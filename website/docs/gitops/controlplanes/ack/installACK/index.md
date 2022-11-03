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

```bash
$ OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
$ ACK_K8S_NAMESPACE=ack-system
$ ACK_K8S_SERVICE_ACCOUNT_NAME=ack-iam-controller
$ cat <<EOF > trust.json
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

$ ACK_CONTROLLER_IAM_ROLE="ack-iam-controller"
$ ACK_CONTROLLER_IAM_ROLE_DESCRIPTION="IRSA role for ACK IAM controller deployment on EKS cluster using Helm charts"
$ aws iam create-role --role-name "${ACK_CONTROLLER_IAM_ROLE}" --assume-role-policy-document file://trust.json --description "${ACK_CONTROLLER_IAM_ROLE_DESCRIPTION}"
$ ACK_CONTROLLER_IAM_ROLE_ARN=$(aws iam get-role --role-name=$ACK_CONTROLLER_IAM_ROLE --query Role.Arn --output text)
```

Create the IAM policy for the IAM controller

```bash
$ BASE_URL=https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/main
$ INLINE_POLICY_URL=${BASE_URL}/config/iam/recommended-inline-policy
$ INLINE_POLICY="$(curl -s ${INLINE_POLICY_URL})"

$ aws iam put-role-policy \
        --role-name "${ACK_CONTROLLER_IAM_ROLE}" \
        --policy-name "ack-recommended-policy" \
        --policy-document "$INLINE_POLICY"

```

Create the IAM controller

```bash
$ aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws

$ RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/iam-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`

$ helm install --create-namespace -n $ACK_K8S_NAMESPACE ack-iam-controller \
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION


$ IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_IAM_ROLE_ARN
$ kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN
$ kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment ack-iam-controller-iam-chart
```

## EC2 controller setup
Create the IAM role with the trust relationship with the Service Account for the EC2 Controller. This time we use the IAM controller itself to create the role.

```bash
$ ACK_K8S_SERVICE_ACCOUNT_NAME=ack-ec2-controller
$ cat <<EOF > ec2-iam-role.yaml
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
  namespace: ack-system
spec:
  description: IRSA role for ACK EC2 controller deployment on EKS cluster using Helm charts
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
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
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:${ACK_K8S_SERVICE_ACCOUNT_NAME}"
            }
          }
        }
      ]
    }
EOF
$ kubectl apply -f ec2-iam-role.yaml
```

Create the EC2 Controller.
```bash
$ RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/ec2-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`

$ helm install --create-namespace -n $ACK_K8S_NAMESPACE ${ACK_K8S_SERVICE_ACCOUNT_NAME} \
  oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION

$ ACK_CONTROLLER_EC2_ROLE_ARN=$(aws iam get-role --role-name=${ACK_K8S_SERVICE_ACCOUNT_NAME} --query Role.Arn --output text)
IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_EC2_ROLE_ARN

$ kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN
$ kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment ack-ec2-controller-ec2-chart
```

## RDS controller setup
Create the IAM role with the trust relationship with the Service Account for the RDS Controller. This time we use the IAM controller itself to create the role.

```bash
$ ACK_K8S_SERVICE_ACCOUNT_NAME=ack-rds-controller
$ cat <<EOF > rds-iam-role.yaml
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
  namespace: ack-system
spec:
  description: IRSA role for ACK RDS controller deployment on EKS cluster using Helm charts
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
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
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:${ACK_K8S_SERVICE_ACCOUNT_NAME}"
            }
          }
        }
      ]
    }
EOF
$ kubectl apply -f rds-iam-role.yaml
```

Create the RDS Controller.
```bash
$ RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/rds-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`

$ helm install --create-namespace -n $ACK_K8S_NAMESPACE ${ACK_K8S_SERVICE_ACCOUNT_NAME} \
  oci://public.ecr.aws/aws-controllers-k8s/rds-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION

$ ACK_CONTROLLER_RDS_ROLE_ARN=$(aws iam get-role --role-name=${ACK_K8S_SERVICE_ACCOUNT_NAME} --query Role.Arn --output text)
$ IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_RDS_ROLE_ARN

$ kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN
$ kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment ack-rds-controller-rds-chart
```

## MQ controller setup
Create the IAM role with the trust relationship with the Service Account for the MQ Controller. This time we use the IAM controller itself to create the role.

```bash
$ ACK_K8S_SERVICE_ACCOUNT_NAME=ack-mq-controller
$ cat <<EOF > mq-iam-role.yaml
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
  namespace: ack-system
spec:
  description: IRSA role for ACK MQ controller deployment on EKS cluster using Helm charts
  name: ${ACK_K8S_SERVICE_ACCOUNT_NAME}
  policies:
    - "arn:aws:iam::aws:policy/AmazonMQFullAccess"
  policyDocument: >
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "ec2:ModifyNetworkInterfaceAttribute",
          "Resource": "*"
        }
      ]
    }
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
              "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:${ACK_K8S_SERVICE_ACCOUNT_NAME}"
            }
          }
        }
      ]
    }
EOF
$ kubectl apply -f mq-iam-role.yaml
```

Create the MQ Controller.
```bash
$ RELEASE_VERSION=`curl -sL https://api.github.com/repos/aws-controllers-k8s/mq-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4`

$ helm install --create-namespace -n $ACK_K8S_NAMESPACE ${ACK_K8S_SERVICE_ACCOUNT_NAME} \
  oci://public.ecr.aws/aws-controllers-k8s/mq-chart --version=$RELEASE_VERSION --set=aws.region=$AWS_REGION


$ ACK_CONTROLLER_MQ_ROLE_ARN=$(aws iam get-role --role-name=${ACK_K8S_SERVICE_ACCOUNT_NAME} --query Role.Arn --output text)
$ IRSA_ROLE_ARN=eks.amazonaws.com/role-arn=$ACK_CONTROLLER_MQ_ROLE_ARN

$ kubectl annotate serviceaccount -n $ACK_K8S_NAMESPACE $ACK_K8S_SERVICE_ACCOUNT_NAME $IRSA_ROLE_ARN
$ kubectl -n $ACK_K8S_NAMESPACE rollout restart deployment ack-mq-controller-mq-chart
```