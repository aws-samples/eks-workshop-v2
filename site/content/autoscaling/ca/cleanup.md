---
title: "Cleanup"
weight: 50
---

```bash wait=300 hook=ca-cleanup
kubectl delete deployment/nginx-to-scaleout
kubectl scale --replicas=0 -n workshop-system deployment/cluster-autoscaler-aws-cluster-autoscaler

export EKS_NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[0]" --output text)
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --filters "Name=tag:eks:nodegroup-name,Values=$EKS_NODEGROUP_NAME" --query "AutoScalingGroups[0].AutoScalingGroupName" --output text)
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $ASG_NAME \
    --desired-capacity 3
```