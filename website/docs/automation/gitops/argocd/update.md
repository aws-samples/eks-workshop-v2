---
title: "Updating the application"
sidebar_position: 20
---

During the development lifecycle, there are new container images or the development team may want to change the configuration of the application. You need to update the application to reflect the latest changes following the GitOps workflow.

In this lab excerise, we'll update the `catalog` application to increase replicas to handle higher traffic with Argo CD. 

Update replicas of the `catalog` application to 3:

```bash
$ yq -ei '.replicas[0].count = 3' /workspace/modules/automation/gitops/argocd/kustomization.yaml
```