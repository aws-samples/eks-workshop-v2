---
title: "Deliver catalog with GitOps"
sidebar_position: 30
---

**GitOps** means a Git repository is the source of truth for what runs in your cluster: instead of running `kubectl apply` by hand, you commit manifests to Git and a controller continuously reconciles the cluster to match. Argo CD is that controller.

The Git repository here is the AWS CodeCommit repo that `prepare-environment` created and seeded for you, `$EKS_CAP_CODECOMMIT_REPO`. It contains the `catalog` service's Kubernetes manifests under a `catalog/` directory.

Right now the `catalog` service is running as part of the base application, applied directly with `kubectl`. We'll hand ownership of it to Argo CD so it's delivered from that repo instead. Two declarative steps make that happen: register this cluster as a deployment target, then create an Argo CD `Application` that points at the repo.

## Register the cluster as a deployment target

Argo CD needs to know _which_ cluster to deploy to. Open-source Argo CD assumes the cluster it runs in, but the managed capability runs off-cluster and has no built-in local target, so we register this cluster explicitly. We define it as a `Secret` that Argo CD recognizes as a deployment target:

::yaml{file="manifests/modules/fastpaths/eks-capabilities/argocd/cluster.yaml" paths="metadata.labels,stringData.name,stringData.server"}

1. The `argocd.argoproj.io/secret-type: cluster` label tells Argo CD this Secret describes a deployment target.
2. We give the target the explicit name `eks-workshop`.
3. The target is identified by the EKS cluster ARN (`$EKS_CLUSTER_AUTO_ARN`), not the usual `https://kubernetes.default.svc`.

Argo CD can already sync to this cluster: during `prepare-environment` the capability created an EKS access entry for its IAM role with the cluster-admin policy attached.

Apply it, resolving the cluster ARN with `envsubst`:

```bash
$ cat ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/argocd/cluster.yaml \
  | envsubst | kubectl apply -f -
secret/eks-workshop created
```

## Create the catalog Application

Now define an Argo CD `Application` that points at the seeded CodeCommit repository. Because the IAM Capability Role grants `codecommit:GitPull`, Argo CD reads the repository **directly** by its HTTPS URL, with no repository Secret, no SSH key, and no Git credential helper to configure.

::yaml{file="manifests/modules/fastpaths/eks-capabilities/argocd/application.yaml" paths="spec.source,spec.destination,spec.syncPolicy"}

1. `source` points at the CodeCommit repo (`$EKS_CAP_CODECOMMIT_URL`); `path: catalog` selects the manifests directory in the repo.
2. `destination.name: eks-workshop` matches the deployment target we just registered.
3. `syncPolicy.automated` with `prune` and `selfHeal` makes Argo CD continuously reconcile the cluster to match Git.

The base application already deployed `catalog` with `kubectl`. Remove it so Argo CD is the sole owner; Argo CD recreates the stack from Git in the next step:

```bash
$ kubectl delete namespace catalog --ignore-not-found
namespace "catalog" deleted
```

Apply the Application, resolving the repository URL with `envsubst`:

```bash
$ kubectl delete application catalog -n argocd --ignore-not-found
$ cat ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/argocd/application.yaml \
  | envsubst | kubectl apply -f -
application.argoproj.io/catalog created
```

Argo CD picks up the new `Application`, pulls the manifests from CodeCommit, creates the `catalog` namespace, and deploys the workloads. Trigger an immediate refresh so we don't wait on the default ~3-minute poll, then wait for the Application to report `Healthy`. A `Healthy` Argo CD Application means its workloads rolled out successfully, so there's no separate rollout check to run:

```bash timeout=600
$ kubectl annotate application catalog -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
$ kubectl wait --for=jsonpath='{.status.health.status}'=Healthy \
  application/catalog -n argocd --timeout=300s
application.argoproj.io/catalog condition met
```

Confirm the final sync and health state:

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```

If you signed in to the UI, click the **catalog** tile on the Applications page to open its resource tree and watch Argo CD reconcile the workloads:

![Argo CD UI showing the catalog application resource tree](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in-app.png)

The `catalog` service is now delivered by GitOps. Any change pushed to the CodeCommit repository will be reconciled to the cluster automatically, which we'll see next.
