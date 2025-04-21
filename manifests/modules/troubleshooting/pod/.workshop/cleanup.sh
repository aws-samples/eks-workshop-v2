#!/bin/bash

# Array to track background processes
declare -a pids

echo "Starting cleanup operations..."

# Function to delete resources in parallel
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local extra_args=$4

    if kubectl get $resource_type $resource_name ${namespace:+-n $namespace} > /dev/null 2>&1; then
        echo "Deleting $resource_type $resource_name ${namespace:+in namespace $namespace}..."
        kubectl delete $resource_type $resource_name ${namespace:+-n $namespace} --ignore-not-found $extra_args &
        pids+=($!)
    else
        echo "$resource_type $resource_name ${namespace:+in namespace $namespace} does not exist."
    fi
}

# Function to patch and delete PVC/PV more efficiently
patch_and_delete() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3

    if kubectl get $resource_type $resource_name ${namespace:+-n $namespace} > /dev/null 2>&1; then
        echo "Patching and deleting $resource_type $resource_name ${namespace:+in namespace $namespace}..."
        # Patch to remove finalizers
        kubectl patch $resource_type $resource_name ${namespace:+-n $namespace} -p '{"metadata":{"finalizers":null}}' --type=merge
        # Delete with force and no grace period
        kubectl delete $resource_type $resource_name ${namespace:+-n $namespace} --ignore-not-found &
        pids+=($!)
    else
        echo "$resource_type $resource_name ${namespace:+in namespace $namespace} does not exist."
    fi
}

###======UI Private Deployment
delete_resource deployment ui-private default

###======ImagePullBackOff - Public Image
delete_resource deployment ui-new default

###======PodStuck - ContainerCreating
delete_resource deployment efs-app default "--force --grace-period=0"

# Handle PVC deletion more efficiently
patch_and_delete pvc efs-claim default

# Find and handle PV in parallel
{
    PV_NAME=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="efs-claim")].metadata.name}')
    if [ -n "$PV_NAME" ]; then
        echo "Patching and deleting PV $PV_NAME..."
        kubectl patch pv "$PV_NAME" -p '{"metadata":{"finalizers":null}}' --type=merge
        kubectl delete pv "$PV_NAME" --ignore-not-found --force --grace-period=0 &
        pids+=($!)
    else
        echo "No PV associated with efs-claim."
    fi
} &
pids+=($!)

# Delete storage class
delete_resource storageclass efs-sc

# Delete CSIDriver efs.csi.aws.com
delete_resource csidriver efs.csi.aws.com


# Wait for all background processes to complete
echo "Waiting for all deletion operations to complete..."
for pid in "${pids[@]}"; do
    wait $pid
done

echo "Cleanup completed."