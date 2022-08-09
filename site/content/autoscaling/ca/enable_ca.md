---
title: "Enable CA"
weight: 30
---

## Enable Cluster Autoscaler

The Cluster Autoscaler component has been pre-installed in the EKS cluster but is scaled down to 0. The first thing we need to do is scale up the replica count:

```bash timeout=180
kubectl scale --replicas=1 -n workshop-system deployment/cluster-autoscaler-aws-cluster-autoscaler

kubectl wait --for=condition=available --timeout=120s -n workshop-system deployment/cluster-autoscaler-aws-cluster-autoscaler
```