---
title: 'Cleanup'
sidebar_position: 90
---

To uninstall Argo CD from the cluster run:

```bash
$ helm uninstall argocd -n argocd
$ kubectl delete namespace argocd
$ kubectl delete namespace argocd-demo
```
