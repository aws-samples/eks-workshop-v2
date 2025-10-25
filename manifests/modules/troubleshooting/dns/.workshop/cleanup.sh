#!/bin/bash

# Clean up any resources created by the user OUTSIDE of Terraform here

# All stdout output will be hidden from the user
# To display a message to the user:
# logmessage "Deleting some resource...."

logmessage "Setting kube-proxy addon to its default configuration"

aws eks update-addon --cluster-name $EKS_CLUSTER_NAME --addon-name kube-proxy --region $AWS_REGION \
  --configuration-values '{}' \
  --resolve-conflicts OVERWRITE
sleep 2
kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy


logmessage "Setting coredns addon to its default configuration"

aws eks update-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE \
    --configuration-values {}
sleep 2
kubectl -n kube-system delete pod -l "k8s-app=coredns"
aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns


logmessage "Setting cluster Security Group to its default configuration"

CLUSTER_SG_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
# echo $CLUSTER_SG_ID
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG_ID --protocol -1 --port -1 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "EKS Cluster SG allows ingress traffic from itself"
aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG_ID --protocol tcp --port 443 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "EKS Cluster SG revoked extra rule for 443"
aws ec2 revoke-security-group-ingress  --group-id $CLUSTER_SG_ID --protocol tcp --port 10250 --source-group $CLUSTER_SG_ID > /dev/null 2>&1 || echo "EKS Cluster SG revoked extra rule for 10250"
sleep 2


logmessage "Ensure application is Ready"

# Recycle workload pods in case stateful pods got restarted
kubectl delete pod -l app.kubernetes.io/created-by=$EKS_CLUSTER_NAME -l app.kubernetes.io/component=service -A
# Wait for the workload pods previously recycled
kubectl wait --for=condition=Ready --timeout=240s pods -l app.kubernetes.io/created-by=$EKS_CLUSTER_NAME -A