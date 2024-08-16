#!/bin/bash

# Ensure SCRIPT_DIR is set
if [ -z "$SCRIPT_DIR" ]; then
    echo "Error: SCRIPT_DIR environment variable is not set."
    exit 1
fi

# Ensure PRIMARY_REGION and SECONDARY_REGION are set
if [ -z "$PRIMARY_REGION" ] || [ -z "$SECONDARY_REGION" ]; then
    echo "Error: PRIMARY_REGION and SECONDARY_REGION must be set."
    exit 1
fi

# Function to run multi-az-get-pods.sh and display region
run_multi_az_script() {
    local region=$1
    echo "Current region: $region"
    echo "Running multi-az-get-pods.sh..."
    $SCRIPT_DIR/multi-az-get-pods.sh
    echo "----------------------------------------"
}

# Run multi-az-get-pods.sh in PRIMARY_REGION
aws configure set default.region $PRIMARY_REGION
run_multi_az_script $PRIMARY_REGION

# Switch to SECONDARY_REGION
echo "Switching to SECONDARY_REGION: $SECONDARY_REGION"
aws configure set default.region $SECONDARY_REGION

# Prepare environment for resiliency module
echo "Preparing environment for resiliency module..."
prepare-environment resiliency

# Verify the EKS cluster in SECONDARY_REGION
echo "Verifying EKS cluster in SECONDARY_REGION..."
aws eks list-clusters

# Check node groups in SECONDARY_REGION
CLUSTER_NAME=$(aws eks list-clusters --query 'clusters[0]' --output text)
echo "Checking node groups for cluster: $CLUSTER_NAME"
aws eks list-nodegroups --cluster-name $CLUSTER_NAME

# Switch back to PRIMARY_REGION
echo "Switching back to PRIMARY_REGION: $PRIMARY_REGION"
aws configure set default.region $PRIMARY_REGION

# Run multi-az-get-pods.sh one last time in PRIMARY_REGION
run_multi_az_script $PRIMARY_REGION

echo "Setup complete.