---
title: "Cleanup"
weight: 40
chapter: false
---

To delete all the resources in this chapter execute the commands below

```bash
# Cleanup K8S resources
kubectl delete deployment pause-pods
kubectl delete priorityclass default
kubectl delete priorityclass pause-pods

# Scale down application #TODO: Change after app
kubectl delete deployment nginx

# Set max capacity (max-size) up to 3 (older value)
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME  --scaling-config minSize=3,maxSize=3,desiredSize=3

# Verify old values of Nodgroup size have been restored
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME --query nodegroup.scalingConfig --output table

```
