environment=${environment:-""}

if [ -z "$environment" ]; then
  export EKS_CLUSTER_NAME="eks-workshop"
  export EKS_CLUSTER_AUTO_NAME="eks-workshop-auto"
else
  export EKS_CLUSTER_NAME="eks-workshop-${environment}"
  export EKS_CLUSTER_AUTO_NAME="eks-workshop-auto-${environment}"
fi

AWS_REGION=${AWS_REGION:-""}

if [ -z "$AWS_REGION" ]; then
  echo "Warning: Defaulting region to us-west-2"

  export AWS_REGION="us-west-2"
fi

SKIP_CREDENTIALS=${SKIP_CREDENTIALS:-""}
USE_CURRENT_USER=${USE_CURRENT_USER:-""}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""} # We check the access key

if [ -z "$SKIP_CREDENTIALS" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

  IDE_ROLE_NAME="${EKS_CLUSTER_NAME}-ide-role"
  IDE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${IDE_ROLE_NAME}"
  
  export RESOURCE_CODEBUILD_ROLE_ARN="${IDE_ROLE_ARN}"
fi

export DOCKER_CLI_HINTS="false"