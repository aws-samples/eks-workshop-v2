---
title: "Cleanup"
weight: 65
---

## Cleanup

```bash wait=30 timeout=120
kubectl delete deployment inflate
kubectl delete provisioner default
```

Finally we need to scale Karpenter back to 0 replicas to disable it:

```bash
kubectl scale --replicas=0 -n workshop-system deployment/karpenter
```