#!/bin/bash
# Runs the Argo CD IAM Identity Center activation in a throwaway Linux container.
#
# Why this exists: activate-user.py drives the AWS console with a headless browser,
# so it is sensitive to the browser build and to whether the profile is fresh. The
# environment that matters is the Workshop Studio pre-provisioning build, which is
# Linux with a clean profile — not a developer's macOS with a warm one. Running it
# here reproduces the real conditions, and iterates in seconds rather than through a
# full `make pre-provision`.
#
# Also sidesteps PEP 668: the container's Python is not externally managed, so pip
# installs without --break-system-packages or a virtualenv.
#
# Usage: bash hack/activate-idc-user.sh [user-name]
#
# Requires AWS credentials in the environment with console federation rights, which
# means temporary credentials: the script refuses to run without a session token.

set -Eeuo pipefail

user_name=${1:-eks-workshop}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

source $SCRIPT_DIR/lib/common-env.sh

CONTAINER_CLI=${CONTAINER_CLI:-docker}

preprovision_dir="$SCRIPT_DIR/../manifests/modules/automation/gitops/argocd/.workshop/terraform/preprovision"
screenshot_dir=${SCREENSHOT_DIR:-/tmp/idc-activation}

# Named by the preprovision Terraform as "${eks_cluster_id}-argocd-idc".
secret_id=${SECRET_ID:-"${EKS_CLUSTER_NAME}-argocd-idc"}

mkdir -p "$screenshot_dir"

if [ -z "${AWS_SESSION_TOKEN:-}" ]; then
  echo "Error: console federation needs temporary credentials, but AWS_SESSION_TOKEN is empty." >&2
  echo "       Assume a role first, then re-run." >&2
  exit 1
fi

if ! aws secretsmanager describe-secret --secret-id "$secret_id" &> /dev/null; then
  echo "Error: secret '$secret_id' not found in $AWS_REGION." >&2
  echo "       It is created by the preprovision Terraform, so run" >&2
  echo "       'make pre-provision action=apply module=automation/gitops/argocd' first," >&2
  echo "       or set SECRET_ID to an existing secret." >&2
  exit 1
fi

# The candidate is only used when the secret holds no working password yet. Generate
# it here rather than hardcoding one, so a failed run does not leave a known value
# behind.
# Mirrors data.aws_secretsmanager_random_password.argocd_admin in the preprovision
# Terraform, so this harness exercises the same password shape the real run uses.
# Identity Center requires upper, lower, a number and a symbol, so punctuation has to
# stay enabled and every included type has to be present. The excluded characters are
# the ones that break quoting on the way through a shell and into the browser.
exclude_chars="\"@/\\'\`"

candidate=$(aws secretsmanager get-random-password \
  --password-length 16 \
  --require-each-included-type \
  --exclude-characters "$exclude_chars" \
  --query RandomPassword --output text)

echo "Activating '$user_name' in $AWS_REGION (secret $secret_id)"
echo "Screenshots: $screenshot_dir"

$CONTAINER_CLI run --rm -i \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
  -e AWS_REGION -e AWS_DEFAULT_REGION="$AWS_REGION" \
  -e ARGOCD_IDC_CANDIDATE_PASSWORD="$candidate" \
  -e USER_NAME="$user_name" -e SECRET_ID="$secret_id" \
  -v "$preprovision_dir:/work:ro" \
  -v "$screenshot_dir:/screenshots" \
  public.ecr.aws/docker/library/python:3.12-slim bash -c '
    set -e
    pip install --quiet playwright boto3
    playwright install --with-deps chromium
    python /work/activate-user.py \
      --region "$AWS_REGION" \
      --user-name "$USER_NAME" \
      --secret-id "$SECRET_ID" \
      --screenshot-dir /screenshots
  '
