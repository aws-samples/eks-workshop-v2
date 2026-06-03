---
title: "Trigger a GitOps update"
sidebar_position: 50
---

With automated sync enabled, the Git repository is now the source of truth for `catalog`. To roll out a change we don't touch the cluster at all — we change the manifests in CodeCommit and let Argo CD reconcile. Let's bump the `catalog` container image from `1.2.1` to `1.2.2` and watch it deploy.

First, clone the CodeCommit repository into the IDE. `git-remote-codecommit` lets `git` authenticate to CodeCommit using your ambient AWS credentials through the `codecommit::` remote helper — no SSH keys, no Git credentials:

```bash
$ rm -rf ~/environment/catalog-gitops
$ git clone codecommit::${AWS_REGION}://${EKS_CAP_CODECOMMIT_REPO} ~/environment/catalog-gitops
```

:::note
The `rm -rf` makes the step idempotent: if you ran the clone earlier or re-entered the lab via `prepare-environment`, any previous working copy is removed before cloning a fresh one. The cleanup hook between fastpath modules also removes this directory, so it may not be present from a previous session.
:::

Confirm the current image tag in the repository:

```bash
$ grep 'image:' ~/environment/catalog-gitops/catalog/deployment.yaml
          image: "public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.1"
```

Update the image tag from `1.2.1` to `1.2.2`:

```bash
$ sed -i 's|retail-store-sample-catalog:1.2.1|retail-store-sample-catalog:1.2.2|' \
  ~/environment/catalog-gitops/catalog/deployment.yaml
$ grep 'image:' ~/environment/catalog-gitops/catalog/deployment.yaml
          image: "public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.2"
```

Commit and push the change. Run the whole block as one chained command — Git needs `user.email` and `user.name` set in this repository before the commit, and the chain (`&&`) guarantees the identity is in place before `git commit` runs:

```bash
$ cd ~/environment/catalog-gitops && \
  git config user.email "you@eksworkshop.com" && \
  git config user.name "EKS Workshop" && \
  git add catalog/deployment.yaml && \
  (git diff --cached --quiet \
     || git commit -m "Bump catalog image to 1.2.2") && \
  git push origin main
```

:::note
If you split the block and run `git commit` standalone, you may see `fatal: unable to auto-detect email address` — that means the `git config` lines didn't run yet in the same shell. Just re-run the chained block above.
:::

That's the entire change — a single commit to Git. Argo CD polls the repository on its own schedule and reconciles when it detects the new revision. To avoid waiting up to ~3 minutes for the next poll, ask Argo CD to refresh the Application now:

```bash
$ kubectl annotate application catalog -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
application.argoproj.io/catalog annotated
```

Wait for the rollout to complete with the new image:

```bash timeout=300
$ kubectl rollout status -n catalog deployment/catalog --timeout=180s
deployment "catalog" successfully rolled out
```

Confirm the running Deployment is now on the new tag:

```bash
$ kubectl get deployment catalog -n catalog \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.2
```

You can also confirm Argo CD reconciled to the new revision and reports healthy:

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```
 on Argo CD UI
![Argo CD UI after Identity Center sign-in](/img/fastpaths/eks-capabilities/argocd/argocd-ui-1.22-app.png) 

:::tip
Because `selfHeal` is enabled, try editing the Deployment directly — for example `kubectl scale -n catalog deployment/catalog --replicas=3`. Argo CD detects the drift from Git and reverts it, because Git, not the cluster, is the source of truth.
:::

That's Lab 2 done. You delivered the `catalog` service through a fully managed GitOps pipeline: a push to CodeCommit became a reconciled rollout on the cluster, with no `kubectl apply` and no self-managed Argo CD to operate.

## Troubleshooting

**`fatal: unable to auto-detect email address`** — Git needs an identity (`user.email`, `user.name`) in this repository before it will commit. Run the chained `cd ... && git config ... && git commit && git push` block above as one unit so the config and commit happen in the same shell.

**`nothing to commit, working tree clean`** — the repository is already at the target image tag (e.g. you ran the lab earlier). The `(git diff --cached --quiet || git commit ...)` guard makes this a no-op; the `git push` that follows is also a no-op against an already-up-to-date branch. The lab still verifies the running deployment is on `1.2.2` either way.

**Argo CD UI keeps showing the old image after `git push`** — Argo CD polls Git on its own ~3-minute schedule. The `kubectl annotate ... refresh=hard` step skips that wait. If you don't see the rollout begin within ~30 seconds of the annotation, double-check the Application's `status.sync.revision` matches your latest commit:

```bash test=false
$ kubectl get application catalog -n argocd \
    -o jsonpath='{.status.sync.revision}{"\n"}'
$ aws codecommit get-branch \
    --repository-name "$EKS_CAP_CODECOMMIT_REPO" --branch-name main \
    --query 'branch.commitId' --output text
```

If they don't match, re-run the annotation. If they match but the Deployment image is still old, the rollout is in flight — wait ~30 more seconds.

Next, we'll use the **kro capability** to declare the complete `carts` stack as a single resource graph.
