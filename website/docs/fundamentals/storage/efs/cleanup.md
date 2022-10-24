---
title: Clean Up
sidebar_position: 40
---

Finally lets reset the `deployment` assets back to its original configuration for the coming modules.

```bash
$ kubectl apply -k /workspace/manifests/assets
$ kubectl -n assets delete pvc efs-claim
$ kubectl delete sc efs-sc
```