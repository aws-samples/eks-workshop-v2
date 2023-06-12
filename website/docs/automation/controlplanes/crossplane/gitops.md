---
title: "GitOps"
sidebar_position: 60
---

:::tip Before you start
Prepare your environment for this section:

```bash
$ argocd login $(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname') --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure
$ echo "ArgoCD Username=admin Password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
$ echo "ArgoCD URL: http://$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')"
```
:::

## GitOpf for Infrastructure


Deploy the Catalog Service and RDS Dabate using GitOps.

```bash

$ argocd app create apps --repo https://github.com/csantanapr/eks-workshop-v2 \
  --revision workshop \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --set-finalizer \
  --upsert \
  --path environment/workspace/modules/automation/controlplanes/crossplane/nested/gitops

```

Open the ArgoCD Console to see the resources provisioned.

