#!/bin/bash
# Verifies this account has what the Amazon EKS Capability for Argo CD needs from
# IAM Identity Center: an active, account-owned instance holding the workshop
# user. Nothing here writes to the directory.
#
# This lives in its own file rather than inline in a local-exec command because
# Terraform reports a provisioner failure by echoing the whole command string.
# Inline, that buries the message below a screen of shell; as a file, the command
# is one line and the message is what the participant actually sees.
#
# Required environment: REGION, ACCOUNT, USER_NAME, USER_EMAIL, GROUP_NAME.

set -euo pipefail

DOCS_URL="https://www.eksworkshop.com/docs/automation/gitops/argocd/"

# Points at the one-time setup rather than restating it. The lab introduction is
# the single source of truth for those commands, so they cannot drift apart.
fail() {
  echo "" >&2
  echo "ERROR: $1" >&2
  echo "" >&2
  echo "  This lab does not set up IAM Identity Center for you." >&2
  echo "  See \"Prerequisites - IAM Identity Center\" in the lab introduction:" >&2
  echo "  $DOCS_URL" >&2
  echo "" >&2
  exit 1
}

IDC_JSON=$(aws sso-admin list-instances --region "$REGION" --output json)

if [ "$(echo "$IDC_JSON" | jq '.Instances | length')" = "0" ]; then
  fail "no IAM Identity Center instance found in $REGION."
fi

IDC_ARN=$(echo "$IDC_JSON" | jq -r '.Instances[0].InstanceArn')
IDC_STATUS=$(echo "$IDC_JSON" | jq -r '.Instances[0].Status // "UNKNOWN"')
IDC_OWNER=$(echo "$IDC_JSON" | jq -r '.Instances[0].OwnerAccountId // empty')
IDENTITY_STORE_ID=$(echo "$IDC_JSON" | jq -r '.Instances[0].IdentityStoreId')

echo "IAM Identity Center: $IDC_ARN (status $IDC_STATUS, owner $IDC_OWNER)"

if [ "$IDC_STATUS" != "ACTIVE" ]; then
  fail "IAM Identity Center instance is $IDC_STATUS, not ACTIVE. Wait for it to finish."
fi

# An instance owned by another account is an organization instance shared from the
# management account. Pointing the capability at it would register an SSO
# application in a directory this account does not own, so stop instead.
if [ -n "$IDC_OWNER" ] && [ "$IDC_OWNER" != "$ACCOUNT" ]; then
  fail "this account uses an organization IAM Identity Center instance owned by $IDC_OWNER, which this lab will not modify."
fi

# --alternate-identifier is a document type, so the AWS CLI rejects shorthand
# syntax for it and requires JSON input.
ALT_ID=$(jq -nc --arg v "$USER_NAME" \
  '{UniqueAttribute:{AttributePath:"UserName",AttributeValue:$v}}')

if ! aws identitystore get-user-id \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --alternate-identifier "$ALT_ID" \
  --region "$REGION" >/dev/null 2>&1; then
  fail "IAM Identity Center user '$USER_NAME' does not exist in this directory."
fi

echo "IAM Identity Center user $USER_NAME found"

# The capability maps a group to the Argo CD ADMIN role, not the user directly, so the
# group has to exist and the user has to be in it. Checked here rather than left to
# the `aws_identitystore_group` data source in the capability module, which reports a
# missing group as a bare lookup failure with no hint about what to create.
GROUP_ALT_ID=$(jq -nc --arg v "$GROUP_NAME" \
  '{UniqueAttribute:{AttributePath:"DisplayName",AttributeValue:$v}}')

if ! GROUP_ID=$(aws identitystore get-group-id \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --alternate-identifier "$GROUP_ALT_ID" \
  --region "$REGION" --query GroupId --output text 2>/dev/null); then
  fail "IAM Identity Center group '$GROUP_NAME' does not exist in this directory."
fi

echo "IAM Identity Center group $GROUP_NAME found"

USER_ID=$(aws identitystore get-user-id \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --alternate-identifier "$ALT_ID" \
  --region "$REGION" --query UserId --output text)

# A group that exists but does not contain the user gives the most confusing failure
# of the lot: the capability comes up healthy and then refuses the participant's
# sign-in, because the ADMIN mapping matches a group they are not in.
MEMBERSHIP=$(jq -nc --arg v "$USER_ID" '{UserId:$v}')

if ! aws identitystore get-group-membership-id \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --group-id "$GROUP_ID" \
  --member-id "$MEMBERSHIP" \
  --region "$REGION" >/dev/null 2>&1; then
  fail "IAM Identity Center user '$USER_NAME' is not a member of group '$GROUP_NAME'."
fi

echo "IAM Identity Center user $USER_NAME is a member of $GROUP_NAME"
