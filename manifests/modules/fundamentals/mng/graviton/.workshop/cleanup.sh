#!/bin/bash

set -e

# Captured before the delete below, because the nodegroup is the only place the
# role is recorded once the module's Terraform state is gone.
node_role=$(aws eks describe-nodegroup --cluster-name "$EKS_CLUSTER_NAME" \
  --nodegroup-name graviton --query 'nodegroup.nodeRole' --output text 2>/dev/null || true)

delete-nodegroup graviton

# The node role's EC2_LINUX access entry is created along with the nodegroup but
# outlives both it and the Terraform-managed role. A second run of this lab
# recreates the role with the same ARN and a new principal id, which the stale
# entry no longer matches, so kubelet is rejected with "Unauthorized" and the new
# nodegroup never leaves CREATING (with no health issue reported). Remove the
# entry so the next run gets a fresh one. The role is read from the nodegroup
# rather than an env var so this works regardless of what the hook inherits.
if [ -n "$node_role" ] && [ "$node_role" != "None" ]; then
  logmessage "Deleting access entry for $node_role..."
  aws eks delete-access-entry --cluster-name "$EKS_CLUSTER_NAME" \
    --principal-arn "$node_role" 2>/dev/null || true
fi
