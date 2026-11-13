echo "Generating temporary AWS credentials..."

session_suffix=$(openssl rand -hex 4)

target_role=${IDE_ROLE_ARN}

ASSUME_ROLE=${ASSUME_ROLE:-""}

if [ ! -z "$ASSUME_ROLE" ]; then
  echo "Assuming role $ASSUME_ROLE"
  target_role=$ASSUME_ROLE
fi

ACCESS_VARS=$(aws sts assume-role --role-arn ${target_role} --role-session-name ${EKS_CLUSTER_NAME}-shell-${session_suffix} --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

# TODO: This should probably not use eval
eval "$ACCESS_VARS"

aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

# The IDE role may only create IAM roles that carry the permissions boundary from
# lab/iam/iam-role-cfn.yaml (stack ${EKS_CLUSTER_NAME}-ide-role, policy
# <stack>-boundary), so tell the labs which one to set.
if [ -z "$ASSUME_ROLE" ]; then
  export EKS_IAM_PERMISSIONS_BOUNDARY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-ide-role-boundary"
  aws_credential_args="$aws_credential_args -e EKS_IAM_PERMISSIONS_BOUNDARY_ARN"
fi