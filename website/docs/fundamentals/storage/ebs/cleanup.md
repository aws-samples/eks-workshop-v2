---
title: Clean Up
sidebar_position: 40
---

Finally lets reset the `StatefulSet` back to its original configuration for the coming modules.

```bash
$ kubectl -n catalog delete statefulset catalog-mysql
$ kubectl apply -k /workspace/manifests/catalog
```