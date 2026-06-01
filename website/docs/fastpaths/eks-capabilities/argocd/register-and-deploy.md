---
title: "Deliver catalog with GitOps"
sidebar_position: 40
---

The `catalog` service is currently running as part of the base application, applied directly with `kubectl`. We'll now hand ownership of it to Argo CD so it's delivered from Git instead. Two declarative steps make that happen: register a deployment target, then create an `Application`.

## Register the cluster as a deployment target

The managed Argo CD capability doesn't deploy to the local cluster automatically — you register it explicitly, and it's identified by its **EKS cluster ARN** rather than the usual in-cluster API URL. We register it under the conventional name `in-cluster`.

The capability auto-created an EKS access entry for its IAM Capability Role during `prepare-environment`, and the role is associated with the cluster-admin access policy, so Argo CD already has the Kubernetes permissions it needs to sync.

```yaml
# manifests/modules/fastpaths/eks-capabilities/argocd/cluster.yaml
apiVersion: v1
kind: Secret
metadata:
  name: in-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: in-cluster
  server: $EKS_CLUSTER_AUTO_ARN
  project: default
```

1. The `argocd.argoproj.io/secret-type: cluster` label tells Argo CD this Secret describes a deployment target.
2. The target is identified by the cluster ARN (`$EKS_CLUSTER_AUTO_ARN`), not `https://kubernetes.default.svc`.

Apply it, resolving the cluster ARN with `envsubst`:

```bash
$ cat ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/argocd/cluster.yaml \
  | envsubst | kubectl apply -f -
secret/in-cluster created
```

## Create the catalog Application

Now define an Argo CD `Application` that points at the seeded CodeCommit repository. Because the IAM Capability Role grants `codecommit:GitPull`, Argo CD reads the repository **directly** by its HTTPS URL — there's no repository Secret, no SSH key, and no Git credential helper to configure.

```yaml
# manifests/modules/fastpaths/eks-capabilities/argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: catalog
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $EKS_CAP_CODECOMMIT_URL
    targetRevision: main
    path: catalog
  destination:
    name: in-cluster
    namespace: catalog
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

1. `repoURL` is the CodeCommit HTTPS endpoint (`$EKS_CAP_CODECOMMIT_URL`); `path: catalog` selects the manifests directory in the repo.
2. `destination.name: in-cluster` matches the deployment target we just registered.
3. `syncPolicy.automated` with `prune` and `selfHeal` makes Argo CD continuously reconcile the cluster to match Git.

Before Argo CD adopts `catalog`, remove the copy the base application applied with `kubectl` so there's a single owner of the namespace:

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

Argo CD picks up the new `Application`, pulls the manifests from CodeCommit, creates the `catalog` namespace, and deploys the workloads. Wait for it to report both `Synced` and `Healthy`:

```bash timeout=300
$ kubectl wait --for=jsonpath='{.status.sync.status}'=Synced \
  application/catalog -n argocd --timeout=180s
application.argoproj.io/catalog condition met
$ kubectl wait --for=jsonpath='{.status.health.status}'=Healthy \
  application/catalog -n argocd --timeout=180s
application.argoproj.io/catalog condition met
```

Inspect the Application's status:

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```

Confirm the workloads Argo CD deployed are running:

```bash timeout=180
$ kubectl rollout status -n catalog deployment/catalog --timeout=150s
deployment "catalog" successfully rolled out
$ kubectl get pods -n catalog
NAME                       READY   STATUS    RESTARTS   AGE
catalog-7d9f4c5b8d-abcde   1/1     Running   0          90s
catalog-mysql-0            1/1     Running   0          90s
```

The `catalog` service is now delivered by GitOps. Any change pushed to the CodeCommit repository will be reconciled to the cluster automatically — which we'll see next.
