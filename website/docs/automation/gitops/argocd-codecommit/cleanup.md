---
title: "Cleanup"
sidebar_position: 90
---

To remove Argo CD configuration for `apps` from the cluster run:

```bash
$ kubectl -n argocd delete secret codecommit-repo
secret "codecommit-repo" deleted
$ kubectl -n argocd delete application apps
application.argoproj.io "apps" deleted
```
