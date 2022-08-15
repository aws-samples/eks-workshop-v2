---
title: "Remove Provisioner"
sidebar_position: 50
---

When you remove a `Provisioner` Karpenter will delete all the associated nodes:

```bash timeout=180 hook=karpenter-remove
kubectl delete provisioner default
```