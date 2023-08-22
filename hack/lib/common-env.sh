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
