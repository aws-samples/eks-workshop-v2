---
title: "Configuring ACK Resources"
sidebar_position: 1
weight: 20
---

Installing a controller consists of three steps:
1. Setup of Iam Role Service Account (IRSA) for the controller. It gives the controller the access rights to the AWS resources it controls.
2. Setup the controller K8S resources via Helm
3. Update the SA annotation to have the IRSA working and restart the controller (to simplify)

The first controller to setup is the IAM one which is going to be used for the step 1 for the other controllers.

## IAM controller setup
Create the IAM role with the trust relationship with the Service Account for the IAM Controller.  

```
export CLUSTER_NAME="cluster-stack"
export AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
ACK_K8S_NAMESPACE=ack-system
export ACK_K8S_SERVICE_ACCOUNT_NAME=ack-iam-controller
read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${ACK_K8S_NAMESPACE}:${ACK_K8S_SERVICE_ACCOUNT_NAME}"
        }
      }
    }
  ]
}
EOF
echo "${TRUST_RELATIONSHIP}" > trust.json

export ACK_CONTROLLER_IAM_ROLE="ack-iam-controller"
ACK_CONTROLLER_IAM_ROLE_DESCRIPTION='IRSA role for ACK IAM controller deployment on EKS cluster using Helm charts'
aws iam create-role --role-name "${ACK_CONTROLLER_IAM_ROLE}" --assume-role-policy-document file://trust.json --description "${ACK_CONTROLLER_IAM_ROLE_DESCRIPTION}"
export ACK_CONTROLLER_IAM_ROLE_ARN=$(aws iam get-role --role-name=$ACK_CONTROLLER_IAM_ROLE --query Role.Arn --output text)
rm trust.json
```

Create the IAM policy for the IAM controller

```
BASE_URL=https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/main
POLICY_ARN_URL=${BASE_URL}/config/iam/recommended-policy-arn
POLICY_ARN="$(wget -qO- ${POLICY_ARN_URL})"

while [ ! -z "$POLICY_ARN" ]; do
    echo -n "Attaching $IFS ... "
    aws iam attach-role-policy \
        --role-name "${ACK_CONTROLLER_IAM_ROLE}" \
        --policy-arn "${POLICY_ARN}"
    echo "ok."
done <<< "$POLICY_ARN_STRINGS"

INLINE_POLICY_URL=${BASE_URL}/config/iam/recommended-inline-policy
INLINE_POLICY="$(wget -qO- ${INLINE_POLICY_URL})"

if [ ! -z "$INLINE_POLICY" ]; then
    echo -n "Putting inline policy ... "
    aws iam put-role-policy \
        --role-name "${ACK_CONTROLLER_IAM_ROLE}" \
        --policy-name "ack-recommended-policy" \
        --policy-document "$INLINE_POLICY"
    echo "ok."
fi
```

Create the IAM controller

```
HELM_EXPERIMENTAL_OCI=1
if ! [ -n "$2" ]; then 
  RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/iam-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`
fi
CHART_EXPORT_PATH=tmp/charts
CHART_REF=iam-chart
CHART_REPO=public.ecr.aws/aws-controllers-k8s/$CHART_REF
CHART_PACKAGE=$CHART_REF-$RELEASE_VERSION.tgz

mkdir -p $CHART_EXPORT_PATH

helm pull oci://$CHART_REPO --version $RELEASE_VERSION -d $CHART_EXPORT_PATH
tar xvf $CHART_EXPORT_PATH/$CHART_PACKAGE -C $CHART_EXPORT_PATH

ACK_K8S_NAMESPACE=ack-system
helm install --create-namespace --namespace $ACK_K8S_NAMESPACE ack-iam-controller \
    --set aws.region="$AWS_REGION" \
    $CHART_EXPORT_PATH/iam-chart

IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_IAM_ROLE_ARN

kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN
kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment $(kubectl get deployments -n $ACK_K8S_NAMESPACE | grep -v NAME | awk '{print $1}')
```

## EC2 controller setup
Create the IAM role with the trust relationship with the Service Account for the EC2 Controller. This time we use the IAM controller itself to create the role.

```
read -r -d '' EC2_IAM_ROLE <<EOF
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ack-ec2-controller
  namespace: ack-system
spec:
  description: IRSA role for ACK EC2 controller deployment on EKS cluster using Helm charts
  name: ack-ec2-controller
  policies:
    - "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  assumeRolePolicyDocument: >
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:ack-ec2-controller"
            }
          }
        }
      ]
    }
EOF

echo "${EC2_IAM_ROLE}" > ec2-iam-role.yaml
kubectl apply -f ec2-iam-role.yaml
```

Create the EC2 Controller.
```
HELM_EXPERIMENTAL_OCI=1
if ! [ -n "$2" ]; then 
  RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/ec2-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`
fi
CHART_EXPORT_PATH=tmp/charts
CHART_REF=ec2-chart
CHART_REPO=public.ecr.aws/aws-controllers-k8s/$CHART_REF
CHART_PACKAGE=$CHART_REF-$RELEASE_VERSION.tgz

mkdir -p $CHART_EXPORT_PATH

helm pull oci://$CHART_REPO --version $RELEASE_VERSION -d $CHART_EXPORT_PATH
tar xvf $CHART_EXPORT_PATH/$CHART_PACKAGE -C $CHART_EXPORT_PATH

ACK_K8S_NAMESPACE=ack-system
helm install --create-namespace --namespace $ACK_K8S_NAMESPACE ack-ec2-controller \
    --set aws.region="$AWS_REGION" \
    $CHART_EXPORT_PATH/ec2-chart

export ACK_CONTROLLER_EC2_ROLE_ARN=$(aws iam get-role --role-name=ack-ec2-controller --query Role.Arn --output text)
IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_EC2_ROLE_ARN

ACK_K8S_SERVICE_ACCOUNT_NAME=ack-ec2-controller
kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN --
kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment $(kubectl get deployments -n $ACK_K8S_NAMESPACE | grep -v NAME | awk '{print $1}')
```

## RDS controller setup
Create the IAM role with the trust relationship with the Service Account for the RDS Controller. This time we use the IAM controller itself to create the role.

```
read -r -d '' RDS_IAM_ROLE <<EOF
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ack-rds-controller
  namespace: ack-system
spec:
  description: IRSA role for ACK RDS controller deployment on EKS cluster using Helm charts
  name: ack-rds-controller
  policies:
    - "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  assumeRolePolicyDocument: >
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:ack-rds-controller"
            }
          }
        }
      ]
    }
EOF

echo "${RDS_IAM_ROLE}" > rds-iam-role.yaml
kubectl apply -f rds-iam-role.yaml
```

Create the RDS Controller.
```
HELM_EXPERIMENTAL_OCI=1
if ! [ -n "$2" ]; then 
  RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/rds-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`
fi
CHART_EXPORT_PATH=tmp/charts
CHART_REF=rds-chart
CHART_REPO=public.ecr.aws/aws-controllers-k8s/$CHART_REF
CHART_PACKAGE=$CHART_REF-$RELEASE_VERSION.tgz

mkdir -p $CHART_EXPORT_PATH

helm pull oci://$CHART_REPO --version $RELEASE_VERSION -d $CHART_EXPORT_PATH
tar xvf $CHART_EXPORT_PATH/$CHART_PACKAGE -C $CHART_EXPORT_PATH

ACK_K8S_NAMESPACE=ack-system
helm install --create-namespace --namespace $ACK_K8S_NAMESPACE ack-rds-controller \
    --set aws.region="$AWS_REGION" \
    $CHART_EXPORT_PATH/$CHART_REF

export ACK_CONTROLLER_RDS_ROLE_ARN=$(aws iam get-role --role-name=ack-rds-controller --query Role.Arn --output text)
IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_RDS_ROLE_ARN

ACK_K8S_SERVICE_ACCOUNT_NAME=ack-rds-controller
kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN --
kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment $(kubectl get deployments -n $ACK_K8S_NAMESPACE | grep -v NAME | awk '{print $1}')
```

## MQ controller setup
Create the IAM role with the trust relationship with the Service Account for the MQ Controller. This time we use the IAM controller itself to create the role.

```
read -r -d '' MQ_IAM_ROLE <<EOF
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ack-mq-controller
  namespace: ack-system
spec:
  description: IRSA role for ACK MQ controller deployment on EKS cluster using Helm charts
  name: ack-mq-controller
  policies:
    - "arn:aws:iam::aws:policy/AmazonMQFullAccess"
  assumeRolePolicyDocument: >
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:ack-mq-controller"
            }
          }
        }
      ]
    }
EOF

echo "${MQ_IAM_ROLE}" > mq-iam-role.yaml
kubectl apply -f mq-iam-role.yaml
```

Create the MQ Controller.
```
HELM_EXPERIMENTAL_OCI=1
if ! [ -n "$2" ]; then 
  RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/mq-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`
fi
CHART_EXPORT_PATH=tmp/charts
CHART_REF=mq-chart
CHART_REPO=public.ecr.aws/aws-controllers-k8s/$CHART_REF
CHART_PACKAGE=$CHART_REF-$RELEASE_VERSION.tgz

mkdir -p $CHART_EXPORT_PATH

helm pull oci://$CHART_REPO --version $RELEASE_VERSION -d $CHART_EXPORT_PATH
tar xvf $CHART_EXPORT_PATH/$CHART_PACKAGE -C $CHART_EXPORT_PATH

ACK_K8S_NAMESPACE=ack-system
helm install --create-namespace --namespace $ACK_K8S_NAMESPACE ack-mq-controller \
    --set aws.region="$AWS_REGION" \
    $CHART_EXPORT_PATH/$CHART_REF

export ACK_CONTROLLER_MQ_ROLE_ARN=$(aws iam get-role --role-name=ack-mq-controller --query Role.Arn --output text)
IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_MQ_ROLE_ARN

ACK_K8S_SERVICE_ACCOUNT_NAME=ack-mq-controller
kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN --
kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment $(kubectl get deployments -n $ACK_K8S_NAMESPACE | grep -v NAME | awk '{print $1}')
```