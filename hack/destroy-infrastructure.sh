#!/bin/bash

environment=$1
cluster=${2:-all}
echo "Destroying infrastructure for environment ${environment} and cluster ${cluster}"

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export USE_CURRENT_USER=${USE_CURRENT_USER:-1};
source $SCRIPT_DIR/lib/common-env.sh

# How long to wait for an in-progress EKS update to finish before deleting, and
# how many times to attempt each cluster delete. EKS rejects DeleteCluster with
# a 409 ("currently has an update in progress") while the control plane is busy,
# and CloudFormation then leaves the cluster stack in DELETE_FAILED.
CLUSTER_IDLE_TIMEOUT=${CLUSTER_IDLE_TIMEOUT:-900}
CLUSTER_IDLE_POLL=${CLUSTER_IDLE_POLL:-20}
DELETE_ATTEMPTS=${DELETE_ATTEMPTS:-2}
DELETE_RETRY_DELAY=${DELETE_RETRY_DELAY:-120}

cluster_exists() {
  aws eks describe-cluster --name "$1" &> /dev/null
}

# Prints the number of updates on the cluster that are still InProgress.
in_progress_updates() {
  local name=$1 count=0 update_id status

  for update_id in $(aws eks list-updates --name "$name" --query 'updateIds[]' --output text 2> /dev/null); do
    [ "$update_id" == "None" ] && continue
    status=$(aws eks describe-update --name "$name" --update-id "$update_id" --query 'update.status' --output text 2> /dev/null || echo "Unknown")
    if [ "$status" == "InProgress" ]; then
      count=$((count + 1))
    fi
  done

  echo "$count"
}

# Waits until the cluster is not CREATING/UPDATING and has no InProgress update,
# or no longer exists. Gives up after CLUSTER_IDLE_TIMEOUT seconds and lets the
# delete try anyway, so a stuck update cannot hang the teardown forever.
wait_for_cluster_idle() {
  local name=$1 deadline status updates
  deadline=$(( $(date +%s) + CLUSTER_IDLE_TIMEOUT ))

  while true; do
    status=$(aws eks describe-cluster --name "$name" --query 'cluster.status' --output text 2> /dev/null || echo "NOT_FOUND")

    if [ "$status" == "NOT_FOUND" ]; then
      return 0
    fi

    updates=0
    if [ "$status" != "CREATING" ] && [ "$status" != "UPDATING" ]; then
      updates=$(in_progress_updates "$name")
      if [ "$updates" == "0" ]; then
        return 0
      fi
    fi

    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "Cluster ${name} still busy (status ${status}, ${updates} update(s) in progress) after ${CLUSTER_IDLE_TIMEOUT}s, deleting anyway"
      return 0
    fi

    echo "Waiting for cluster ${name} to be idle (status ${status}, ${updates} update(s) in progress)"
    sleep "$CLUSTER_IDLE_POLL"
  done
}

# Deletes one cluster with eksctl, retrying when the delete fails while the
# cluster still exists (typically the 409 above, which leaves a DELETE_FAILED
# cluster stack that a second `eksctl delete cluster` picks up). Returns non-zero
# if the cluster could not be deleted, so the caller can fail the job instead of
# leaking it.
delete_cluster() {
  local name=$1 attempt=1 rc

  while true; do
    wait_for_cluster_idle "$name"

    rc=0
    bash $SCRIPT_DIR/exec.sh "${environment}" "eksctl delete cluster --name ${name} --region ${AWS_REGION} --wait --force --disable-nodegroup-eviction --timeout 45m" || rc=$?

    if [ $rc -eq 0 ]; then
      echo "Deleted cluster ${name}"
      return 0
    fi

    if ! cluster_exists "$name"; then
      echo "eksctl exited with ${rc} for ${name} but the cluster is gone, treating as deleted"
      return 0
    fi

    if [ $attempt -ge "$DELETE_ATTEMPTS" ]; then
      echo "Error: failed to delete cluster ${name} after ${attempt} attempt(s) (last exit code ${rc})"
      return 1
    fi

    attempt=$((attempt + 1))
    echo "Delete of cluster ${name} failed with exit code ${rc}, retrying in ${DELETE_RETRY_DELAY}s (attempt ${attempt}/${DELETE_ATTEMPTS})"
    sleep "$DELETE_RETRY_DELAY"
  done
}

pids=()
names=()

cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_NAME}" &> /dev/null || cluster_exists=$?

if [ $cluster_exists -eq 0 ] && [[ "$cluster" == "standard" || "$cluster" == "all" ]]; then
  echo "Deleting cluster ${EKS_CLUSTER_NAME}"
  bash $SCRIPT_DIR/shell.sh "${environment}" 'delete-environment' || true
  delete_cluster "${EKS_CLUSTER_NAME}" &
  pids+=($!)
  names+=("${EKS_CLUSTER_NAME}")
else
  echo "Cluster ${EKS_CLUSTER_NAME} does not exist or skipped"
fi

export EKS_CLUSTER_AUTO_NAME="${EKS_CLUSTER_AUTO_NAME}"
auto_cluster_exists=0
aws eks describe-cluster --name "${EKS_CLUSTER_AUTO_NAME}" &> /dev/null || auto_cluster_exists=$?

if [ $auto_cluster_exists -eq 0 ] && [[ "$cluster" == "auto" || "$cluster" == "all" ]]; then
  echo "Deleting auto mode cluster ${EKS_CLUSTER_AUTO_NAME}"
  bash $SCRIPT_DIR/shell.sh "${environment}" 'delete-environment' || true
  delete_cluster "${EKS_CLUSTER_AUTO_NAME}" &
  pids+=($!)
  names+=("${EKS_CLUSTER_AUTO_NAME}")
else
  echo "Auto mode cluster ${EKS_CLUSTER_AUTO_NAME} does not exist or skipped"
fi

# A bare `wait` always returns 0, which hid failed deletes and leaked clusters.
# Wait on each delete individually and remember any failure.
failed=()
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    failed+=("${names[$i]}")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  # Keep the IDE role so a rerun (for example the Test cleanup workflow) finds
  # the environment in the same state.
  echo "Error: failed to delete cluster(s): ${failed[*]}"
  exit 1
fi

# Only delete ide-role if all clusters are deleted
if [ "$cluster" == "all" ]; then
  aws cloudformation delete-stack --stack-name ${EKS_CLUSTER_NAME}-ide-role || true
  echo "Deleted role"
fi
