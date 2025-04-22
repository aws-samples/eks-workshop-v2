#!/bin/bash

set -e

# Array to track background processes
declare -a pids

logmessage "Starting cleanup operations..."

# Function to delete resources in parallel
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local extra_args=$4

    if kubectl get $resource_type $resource_name ${namespace:+-n $namespace} > /dev/null 2>&1; then
        logmessage "Deleting $resource_type $resource_name ${namespace:+in namespace $namespace}..."
        kubectl delete $resource_type $resource_name ${namespace:+-n $namespace} --ignore-not-found $extra_args &
        pids+=($!)
    else
        logmessage "$resource_type $resource_name ${namespace:+in namespace $namespace} does not exist."
    fi
}

# Function to patch and delete PVC/PV more efficiently
patch_and_delete() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3

    if kubectl get $resource_type $resource_name ${namespace:+-n $namespace} > /dev/null 2>&1; then
        logmessage "Patching and deleting $resource_type $resource_name ${namespace:+in namespace $namespace}..."
        # Patch to remove finalizers
        kubectl patch $resource_type $resource_name ${namespace:+-n $namespace} -p '{"metadata":{"finalizers":null}}' --type=merge
        # Delete with force and no grace period
        kubectl delete $resource_type $resource_name ${namespace:+-n $namespace} --ignore-not-found &
        pids+=($!)
    else
        logmessage "$resource_type $resource_name ${namespace:+in namespace $namespace} does not exist."
    fi
}

###======UI Private Deployment
delete_resource deployment ui-private default

###======ImagePullBackOff - Public Image
delete_resource deployment ui-new default

###======PodStuck - ContainerCreating
delete_resource deployment efs-app default
delete_resource pod "-l app=efs-app" "--force"

# Find and handle PV in parallel
{
    PV_NAME=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="efs-claim")].metadata.name}')
    if [ -n "$PV_NAME" ]; then
        logmessage "Patching and deleting PV $PV_NAME..."        
        patch_and_delete pv "$PV_NAME" default
        pids+=($!)
    else
        logmessage "No PV associated with efs-claim."
    fi
} &
pids+=($!)

# Delete storage class
delete_resource storageclass efs-sc

# Delete CSIDriver efs.csi.aws.com
delete_resource csidriver efs.csi.aws.com


# Wait for all background processes to complete
logmessage "Waiting for all deletion operations to complete..."
for pid in "${pids[@]}"; do
    wait $pid
done

logmessage "Cleanup completed."