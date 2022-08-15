---
title: "Enable CA"
weight: 30
---

## Enable Cluster Autoscaler

The Cluster Autoscaler component has been pre-installed in the EKS cluster but is scaled down to 0. The first thing we need to do is scale up the replica count:

```bash timeout=240
kubectl scale --replicas=1 -n workshop-system deployment/cluster-autoscaler-aws-cluster-autoscaler

kubectl rollout status deployment/cluster-autoscaler-aws-cluster-autoscaler -n workshop-system --timeout 180s
```