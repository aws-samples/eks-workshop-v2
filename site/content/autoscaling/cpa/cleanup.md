---
title: "Clean Up"
date: 2022-08-01T00:00:00-03:00
weight: 4
---

### Cleaning up

Delete cluster proportional autoscaler from the EKS cluster and reset the node group:

```bash wait=120 timeout=300 hook=cpa-cleanup
kubectl delete deployment dns-autoscaler --namespace=kube-system
kubectl delete cm dns-autoscaler --namespace=kube-system
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME  --scaling-config desiredSize=$ORIGINAL_DESIRED_SIZE
aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME
```

Finally reset CoreDNS replicas back to its original configuration:

```bash expectError=true
kubectl scale --replicas=2 --namespace kube-system deployment/coredns
```