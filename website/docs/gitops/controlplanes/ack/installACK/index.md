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
OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
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
ACK_CONTROLLER_IAM_ROLE_ARN=$(aws iam get-role --role-name=$ACK_CONTROLLER_IAM_ROLE --query Role.Arn --output text)
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

## RDS controller setup

## MQ controller setup