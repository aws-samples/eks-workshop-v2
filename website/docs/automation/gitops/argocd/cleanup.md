---
title: 'Cleanup'
sidebar_position: 90
---

To uninstall Argo CD apps from the cluster run:

```bash
$ argocd app delete argocd-demo -y
$ kubectl delete namespace argocd-demo
```
