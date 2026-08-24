#!/bin/bash

set -e

# This lab pins the catalog Deployment to the spot nodegroup with a
# nodeSelector. Deleting the nodegroup (below) is asynchronous, so if catalog
# is still scheduled there its pods get terminated along with the nodes and race
# the environment reset's readiness wait, which then fails with a transient
# "pods ... not found". Move catalog back onto the default nodes and let it
# settle first so nothing base-app depends on the spot nodes when they go away.
#
# A merge patch rather than a JSON-patch `remove`, which errors when the path is
# already absent and would need its output discarded to stay quiet. Guarding on
# the Deployment existing keeps this a no-op on a second run (the hook also runs
# when a participant has deleted the namespace) without hiding real failures.
if kubectl -n catalog get deployment catalog >/dev/null 2>&1; then
  kubectl -n catalog patch deployment catalog --type=merge \
    -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
  kubectl -n catalog rollout status deployment/catalog --timeout=150s || true
fi

# Captured before the delete below, because the nodegroup is the only place the
# role is recorded once the module's Terraform state is gone.
node_role=$(aws eks describe-nodegroup --cluster-name "$EKS_CLUSTER_NAME" \
  --nodegroup-name managed-spot --query 'nodegroup.nodeRole' --output text 2>/dev/null || true)

delete-nodegroup managed-spot

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
