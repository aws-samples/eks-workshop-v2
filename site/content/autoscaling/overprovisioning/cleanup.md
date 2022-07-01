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

# Set ASG value to previous values

# Get Cluster Name
export EKS_CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)

# Get ASG name
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='$EKS_CLUSTER_NAME']].AutoScalingGroupName" --output text)

# Set ASG config
aws autoscaling \
    update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_NAME} \
    --min-size 3 \
    --desired-capacity 3 \
    --max-size 3
```
