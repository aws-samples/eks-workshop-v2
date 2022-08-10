---
title: "Enable Karpenter"
weight: 20
---

## Enable Karpenter

Karpenter has been pre-installed in the EKS cluster but is scaled down to 0. The first thing we need to do is scale up the replica count:

```bash timeout=240
kubectl scale --replicas=1 -n workshop-system deployment/karpenter

kubectl rollout status deployment/karpenter -n workshop-system --timeout 180s
```