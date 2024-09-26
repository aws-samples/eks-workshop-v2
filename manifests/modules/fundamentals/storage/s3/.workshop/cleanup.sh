# #!/bin/bash


# # Ensure cleanup is all good before deploying!
# Replace echo with logmessage

# Anything user has created after prepare-environment

set -e


addon_exists=$(aws eks list-addons --cluster-name $EKS_CLUSTER_NAME --query "addons[? @ == 'aws-mountpoint-s3-csi-driver']" --output text)

# Check if the S3 CSI driver addon exists
if [ ! -z "$addon_exists" ]; then
  # Delete if so
  echo "Deleting S3 CSI driver addon..."

  aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver

  aws eks wait addon-deleted --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
fi

# Check if the bucket exists
# aws s3 ls $BUCKET_NAME
# bucket_exists=$?

# if [ $bucket_exists -eq 0 ]; then
#     echo "The bucket $BUCKET_NAME exists"
#     # Perform additional actions if the bucket exists
#     echo "Deleting bucket $BUCKET_NAME and its objects"
#     aws s3 rb s3://$BUCKET_NAME --force
# fi

# Extract IAM Role name from ARN
# ROLE_NAME=$(echo "$S3_CSI_ADDON_ROLE" | awk -F'/' '{print $NF}')
# role_exists=$(aws iam get-role --role-name "$ROLE_NAME")

# # Check if the IAM CSI Driver role exists
# if [ ! -z "$role_exists" ]; then
#     echo "The IAM role $S3_CSI_ADDON_ROLE exists"

#     # Get the attached policy ARN
#     POLICY_ARN=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[0].PolicyArn" --output text)

#     # Detach the policy
#     aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
    
#     echo "Policy $POLICY_ARN detached from role $ROLE_NAME"

#     # Perform additional actions if the role exists
#     echo "Deleting IAM role $S3_CSI_ADDON_ROLE"
#     aws iam delete-role --role-name "$ROLE_NAME"
# fi

kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl delete -f-

# Scale down assets
# kubectl scale -n assets --replicas=0 deployment/assets

