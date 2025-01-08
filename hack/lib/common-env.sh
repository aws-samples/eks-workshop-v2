environment=${environment:-""}

if [ -z "$environment" ]; then
  export EKS_CLUSTER_NAME="eks-workshop"
else
  export EKS_CLUSTER_NAME="eks-workshop-${environment}"
fi

AWS_REGION=${AWS_REGION:-""}

if [ -z "$AWS_REGION" ]; then
  echo "Warning: Defaulting region to us-west-2"

  export AWS_REGION="us-west-2"
fi

SKIP_CREDENTIALS=${SKIP_CREDENTIALS:-""}

if [ -z "$SKIP_CREDENTIALS" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

  IDE_ROLE_NAME="${EKS_CLUSTER_NAME}-ide-role"
  IDE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${IDE_ROLE_NAME}"
fi

export DOCKER_CLI_HINTS="false"