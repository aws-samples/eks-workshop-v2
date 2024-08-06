echo "Generating temporary AWS credentials..."

session_suffix=$(openssl rand -hex 4)

ACCESS_VARS=$(aws sts assume-role --role-arn ${IDE_ROLE_ARN} --role-session-name ${EKS_CLUSTER_NAME}-shell-${session_suffix} --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

# TODO: This should probably not use eval
eval "$ACCESS_VARS"

aws_credential_args="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"