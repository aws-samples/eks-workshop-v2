#!/bin/bash

# Special echo to print specific output to the user and hide all other outputs
exec 3>&1
special_echo() {
  echo "$@" >&3
}

# Get the path where lad-setup.sh script is saved
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "`date -u` - Lab Setup Started" >> $SCRIPT_DIR/lab-setup.log

# Execute script in verbose mode and send output to a log file
exec &>> $SCRIPT_DIR/lab-setup.log
set -x

special_echo "Applying configuration."

#############################################
### Break kube-proxy pods by using a wrong configuration
#############################################

# Check whether kube-proxy addon is already modified. If so, return it to the default config before modifying it to avoid addon stuck in Updating state.
output=$(aws eks describe-addon --cluster-name $EKS_CLUSTER_NAME --addon-name kube-proxy --query 'addon.configurationValues' --region $AWS_REGION --output text)
if [[ "$output" != "{}" ]]; then
  # Rollback kube-proxy addon to default configuration
  aws eks update-addon --cluster-name $EKS_CLUSTER_NAME --addon-name kube-proxy --region $AWS_REGION \
    --configuration-values '{}' \
    --resolve-conflicts OVERWRITE
  sleep 2
  kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
  aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy
fi

# Update kube-proxy to IPVS mode, but use a wrong scheduler value
aws eks update-addon --cluster-name $EKS_CLUSTER_NAME --addon-name kube-proxy --region $AWS_REGION \
  --configuration-values '{"ipvs": {"scheduler": "r"}, "mode": "ipvs"}' \
  --resolve-conflicts OVERWRITE
sleep 2
kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy

#############################################
### Break coredns pod scheduling
#############################################

# Update coredns node-selector to a node label which is not used by workshop nodes
# Coredns will be stuck in Pending state
# No need to check for coredns addon in non-default config, because scaling replicas to 0 makes addon update process to complete.
kubectl scale deployment coredns --replicas=0 -n kube-system
sleep 2
aws eks update-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE \
    --configuration-values '{"nodeSelector":{"workshop-default":"no"},"replicaCount":0}'

aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns

kubectl scale deployment coredns --replicas=2 -n kube-system

#############################################
### Block DNS traffic using SG 
#############################################

CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
# echo $CLUSTER_SG_ID
aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "Config 1 already applied. Continue reading the rest of lab instructions."
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol tcp --port 443 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "Config 2 already applied. Continue reading the rest of lab instructions."
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol tcp --port 10250 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "Config 3 already applied. Continue reading the rest of lab instructions."

echo "`date -u` - Lab Setup Completed" >> $SCRIPT_DIR/lab-setup.log
special_echo "Configuration applied successfully!"