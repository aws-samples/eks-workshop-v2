check=$(aws eks list-fargate-profiles --cluster-name $EKS_CLUSTER_NAME --query "fargateProfileNames[? @ == 'checkout-profile']" --output text)

if [ ! -z "$check" ]; then
  logmessage "Deleting Fargate profile..."

  aws eks delete-fargate-profile --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --fargate-profile-name checkout-profile
fi