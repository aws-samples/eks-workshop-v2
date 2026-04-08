---
title: "Updating an application"
sidebar_position: 40
---

Now that we have deployed our application with Argo CD, let's explore how we can use GitOps principles to update its configuration. In this example, we'll increase the number of `replicas` for the `ui` deployment from 1 to 3 using Helm values.

First, we'll create a `values.yaml` file that configures the number of replicas:

::yaml{file="manifests/modules/automation/gitops/argocd/update-application/values.yaml"}

Let's copy this configuration file to our Git repository directory:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/argocd/update-application/values.yaml \
  ~/environment/argocd/ui
```

After adding this file, our Git directory structure should look like this:

```bash
$ tree ~/environment/argocd
`-- ui
    |-- Chart.yaml
    `-- values.yaml
```

Now we'll commit and push our changes to the Git repository:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Update UI service replicas"
$ git -C ~/environment/argocd push
```

At this point, Argo CD will detect that the application state in the repository has changed. You can either click `Refresh` and then `Sync` in the Argo CD UI, or use the `argocd` CLI to synchronize the application:

```bash
$ argocd app sync ui
$ argocd app wait ui --timeout 120
```

After synchronization completes, the UI deployment should now have 3 pods running:

![argocd-update-application](/docs/automation/gitops/argocd/argocd-update-application.webp)

To verify that our update was successful, let's check the deployment and pod status:

```bash hook=update
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           3m33s
$ kubectl get pod -n ui
NAME                 READY   STATUS    RESTARTS   AGE
ui-6d5bb7b95-hzmgp   1/1     Running   0          61s
ui-6d5bb7b95-j28ww   1/1     Running   0          61s
ui-6d5bb7b95-rjfxd   1/1     Running   0          3m34s
```

This demonstrates how GitOps allows us to make configuration changes through version control. By updating our repository and syncing with Argo CD, we've successfully scaled our UI deployment without directly interacting with the Kubernetes API.
