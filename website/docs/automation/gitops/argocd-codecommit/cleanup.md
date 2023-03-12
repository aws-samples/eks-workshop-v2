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

Cleanup CodeCommit repository:

- delete branch `argocd`
- delete local clone of `gitops` repository

```bash
$ cd ~/environment/gitops
$ git checkout -b default
$ git push --set-upstream origin default
$ aws codecommit update-default-branch --repository-name ${EKS_CLUSTER_NAME}-gitops --default-branch-name default
$ codecommit delete-branch --repository-name ${EKS_CLUSTER_NAME}-gitops --branch-name argocd
$ cd ..
$ rm -rf gitops
```
