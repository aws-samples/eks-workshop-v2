---
title: "Setup"
sidebar_position: 50
---

We'll create templates for a set of ArgoCD applications using the DRY (Don't Repeat Yourself) approach with Helm charts:

```text
.
|-- app-of-apps
|   |-- Chart.yaml
|   |-- templates
|   |   |-- _application.yaml
|   |   `-- application.yaml
|   `-- values.yaml
|-- ui
`-- catalog
    ...
```

The `_application.yaml` is a template file which will be used to dynamically create applications based on a list of component names:

<!-- prettier-ignore-start -->
::yaml{file="manifests/modules/automation/gitops/argocd/app-of-apps/templates/_application.yaml"}
<!-- prettier-ignore-end -->

The `values.yaml` file specifies a list of components for which ArgoCD applications will be generated, as well as configuration related to the Git repository that will be common across all applications:

::yaml{file="manifests/modules/automation/gitops/argocd/app-of-apps/values.yaml"}

First, let's copy this foundational App of Apps configuration to our Git directory:

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/argocd/app-of-apps ~/environment/argocd/
$ yq -i ".spec.source.repoURL = env(GITOPS_REPO_URL_ARGOCD)" ~/environment/argocd/app-of-apps/values.yaml
```

Now, let's commit and push these changes to the Git repository:

```bash wait=10
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding App of Apps"
$ git -C ~/environment/argocd push
```

Next, we need to create a new Argo CD Application to implement the App of Apps pattern. While doing this, we'll enable ArgoCD to automatically [synchronize](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/) the state in the cluster with the configuration in the Git repository using the `--sync-policy automated` flag:

```bash
$ argocd app create apps --repo $GITOPS_REPO_URL_ARGOCD \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated --self-heal --auto-prune \
  --set-finalizer \
  --upsert \
  --path app-of-apps
 application 'apps' created
$ argocd app wait apps --timeout 120
```

Open the Argo CD UI and navigate to the main "Applications" page. Our App of Apps configuration has been deployed and synced, but except for the UI component, all of the workload apps are marked as "Unknown".

![argocd-ui-apps.png](assets/argocd-ui-apps-unknown.webp)

We will deploy the configurations for the workloads in the next step.
