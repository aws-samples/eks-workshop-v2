echo "Generating temporary AWS credentials..."

ACCESS_VARS=$(aws sts assume-role --role-arn $ASSUME_ROLE --role-session-name eks-workshop-shell --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

# TODO: This should probably not use eval
eval "$ACCESS_VARS"
