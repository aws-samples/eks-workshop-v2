---
title: "Cleanup"
sidebar_position: 90
---

To remove Argo CD configuration for `apps` and secret from the cluster run:

```bash
$ kubectl -n argocd delete application apps
application.argoproj.io "apps" deleted
$ kubectl -n argocd delete secret git-repo --ignore-not-found
secret "git-repo" deleted
```
