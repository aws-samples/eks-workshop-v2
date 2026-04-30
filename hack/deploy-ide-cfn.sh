#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

outfile=$(mktemp)

bash $SCRIPT_DIR/build-ide-cfn.sh $outfile

REPOSITORY_OWNER=${REPOSITORY_OWNER:-"aws-samples"}
REPOSITORY_NAME=${REPOSITORY_NAME:-"eks-workshop-v2"}
REPOSITORY_REF=${REPOSITORY_REF:-"main"}

source $SCRIPT_DIR/lib/resolve-source-ip.sh

STACK_NAME="$EKS_CLUSTER_NAME-cfn"

aws cloudformation deploy --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM --disable-rollback --template-file $outfile \
  --parameter-overrides \
    RepositoryOwner="$REPOSITORY_OWNER" \
    RepositoryName="$REPOSITORY_NAME" \
    RepositoryRef="$REPOSITORY_REF" \
    InboundCIDR="$INBOUND_CIDRS"

if [ -z "$CI" ]; then
  IDE_URL=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`IdeUrl`].OutputValue' --output text)

  IDE_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id "$STACK_NAME-password" --query 'SecretString' --output text | jq -r '.password')

  echo ""
  echo "IDE URL:      $IDE_URL"
  echo "IDE Password: $IDE_PASSWORD"
fi
