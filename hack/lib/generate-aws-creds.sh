aws_credential_args=""

ASSUME_ROLE=${ASSUME_ROLE:-""}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}

if [ ! -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "Using environment AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY"

  aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
elif [ ! -z "$ASSUME_ROLE" ]; then
  echo "Generating temporary AWS credentials..."

  ACCESS_VARS=$(aws sts assume-role --role-arn $ASSUME_ROLE --role-session-name ${EKS_CLUSTER_NAME}-shell --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

  # TODO: This should probably not use eval
  eval "$ACCESS_VARS"

  aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
else
  echo "Inheriting credentials from instance profile"
fi