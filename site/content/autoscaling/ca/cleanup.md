---
title: "Cleanup"
weight: 50
---

```bash wait=180 timeout=300
kubectl delete deployment/nginx-to-scaleout
kubectl scale --replicas=0 -n workshop-system deployment/cluster-autoscaler-aws-cluster-autoscaler

export EKS_NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[0]" --output text)
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME  --scaling-config desiredSize=3
aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME
```