---
title: "Trigger a GitOps update"
sidebar_position: 40
---

With automated sync enabled, the Git repository is now the source of truth for `catalog`. To roll out a change we don't touch the cluster at all. We change the manifests in CodeCommit and let Argo CD reconcile. Let's scale the `catalog` Deployment from 1 replica to 2 and watch it deploy.

First, clone the CodeCommit repository into the IDE. `git-remote-codecommit` lets `git` authenticate to CodeCommit using your ambient AWS credentials through the `codecommit::` remote helper, with no SSH keys and no Git credentials. The `rm -rf` first clears any previous clone so the step is safe to re-run:

```bash
$ rm -rf ~/environment/catalog-gitops
$ git clone codecommit::${AWS_REGION}://${EKS_CAP_CODECOMMIT_REPO} ~/environment/catalog-gitops
```

Confirm the current replica count in the repository:

```bash
$ grep 'replicas:' ~/environment/catalog-gitops/catalog/deployment.yaml
  replicas: 1
```

Update it from 1 to 2:

```bash
$ sed -i 's|replicas: 1|replicas: 2|' \
  ~/environment/catalog-gitops/catalog/deployment.yaml
$ grep 'replicas:' ~/environment/catalog-gitops/catalog/deployment.yaml
  replicas: 2
```

Commit and push the change. Run the whole block as one chained command, because Git needs `user.email` and `user.name` set in this repository before the commit, and the chain (`&&`) guarantees the identity is in place before `git commit` runs:

```bash
$ cd ~/environment/catalog-gitops && \
  git config user.email "you@eksworkshop.com" && \
  git config user.name "EKS Workshop" && \
  git add catalog/deployment.yaml && \
  (git diff --cached --quiet \
     || git commit -m "Scale catalog to 2 replicas") && \
  git push origin main
```

:::note
If you split the block and run `git commit` standalone, you may see `fatal: unable to auto-detect email address`, which means the `git config` lines didn't run yet in the same shell. Just re-run the chained block above.
:::

That's the entire change: a single commit to Git. Argo CD polls the repository on its own schedule and reconciles when it detects the new revision. To avoid waiting up to around 3 minutes for the next poll, ask Argo CD to refresh the Application now:

```bash
$ kubectl annotate application catalog -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
application.argoproj.io/catalog annotated
```

Wait for the rollout to complete with the second replica:

```bash timeout=300
$ kubectl rollout status -n catalog deployment/catalog --timeout=180s
deployment "catalog" successfully rolled out
```

Confirm the running Deployment now has 2 replicas:

```bash
$ kubectl get deployment catalog -n catalog \
  -o jsonpath='{.status.readyReplicas}{"\n"}'
2
```

You can also confirm Argo CD reconciled to the new revision and reports healthy:

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```

If you signed in to the UI, click the **catalog** tile to open its resource tree and see the second replica appear:

![Argo CD UI showing the reconciled catalog application](/img/fastpaths/eks-capabilities/argocd/argocd-ui-1.22-app.png)

:::tip
Because `selfHeal` is enabled, try editing the Deployment directly, for example `kubectl scale -n catalog deployment/catalog --replicas=3`. Argo CD detects the drift from Git and reverts it, because Git, not the cluster, is the source of truth.
:::

That's the Argo CD lab done. You delivered the `catalog` service through a fully managed GitOps pipeline: a push to CodeCommit became a reconciled rollout on the cluster, with no `kubectl apply` and no self-managed Argo CD to operate.

Next, we'll use the **kro capability** to declare the complete `carts` stack as a single resource graph.
