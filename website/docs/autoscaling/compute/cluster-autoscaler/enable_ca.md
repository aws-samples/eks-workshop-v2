---
title: "Enable CA"
sidebar_position: 30
---

The Cluster Autoscaler component has been pre-installed in the EKS cluster but is scaled down to 0. Now, let's scale up the replica count:

```bash timeout=240
$ kubectl scale --replicas=1 -n kube-system \
  deployment/cluster-autoscaler-aws-cluster-autoscaler
$ kubectl rollout status \
  deployment/cluster-autoscaler-aws-cluster-autoscaler \
  -n kube-system --timeout 180s
```
