#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

outfile=$(mktemp)

bash $SCRIPT_DIR/build-ide-cfn.sh $outfile

INBOUND_CIDRS="${INBOUND_IP_ADDRESS:+${INBOUND_IP_ADDRESS}/32}"
INBOUND_CIDRS="${INBOUND_CIDRS:-0.0.0.0/0}"

aws cloudformation deploy --stack-name "$EKS_CLUSTER_NAME-ide" \
  --capabilities CAPABILITY_NAMED_IAM --disable-rollback --template-file $outfile \
  --parameter-overrides InboundCIDR="$INBOUND_CIDRS"