---
title: Helm
sidebar_custom_props: { "module": true }
sidebar_position: 50
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=10
$ prepare-environment introduction/helm
```

:::

Although we will primarily be interacting with Kustomize in this workshop, there will be situations where Helm will be used to install certain packages in the EKS cluster. In this lab we give a brief introduction to Helm, and we'll demonstrate how to use it to install a pre-packaged application.

:::info

This lab does not cover the authoring of Helm charts for your own workloads. For more information on this topic see this [guide](https://helm.sh/docs/chart_template_guide/).

:::

[Helm](https://helm.sh) is a package manager for Kubernetes that helps you define, install, and upgrade Kubernetes applications. It uses a packaging format called charts, which contain all the necessary Kubernetes resource definitions to run an application. Helm simplifies the deployment and management of applications on Kubernetes clusters.

## Helm CLI

The `helm` CLI tool is typically used in conjunction with a Kubernetes cluster to manage the deployment and lifecycle of applications. It provides a consistent and repeatable way to package, install, and manage applications on Kubernetes, making it easier to automate and standardize application deployments across different environments.

The CLI is already installed in our IDE:

```bash
$ helm version
```

## Installing a Helm chart

Let's install the UI component of our sample application using its Helm chart instead of Kustomize manifests. When you install a chart using the Helm package manager, it creates a new **release** for that chart. Each release is tracked by Helm and can be upgraded, rolled back, or uninstalled independently from other releases.

First let's delete the existing UI application:

```bash
$ kubectl delete namespace ui
```

Next we can install the chart:

```bash hook=install
$ helm install ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --wait
```

We can break this command down as follows:

- Use the `install` sub-command to instruct Helm to install a chart
- Name the release `ui`
- Use the chart hosted in [ECR Public](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui-chart) with a specific version
- Install the chart in the `ui` namespace
- Wait for Pods in the release to get to a ready state

Once the chart is installed we can list the releases in our EKS cluster:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                               APP VERSION
ui     ui         1         2024-06-11 03:58:39.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X
```

We can also see application running in the namespace we specified:

```bash
$ kubectl get pod -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-zplwx      1/1     Running   0          119s
```

## Configuring chart options

In the example above we installed the chart with its [default configuration](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/chart/values.yaml). Often you'll need to provide configuration **values** to charts during installation to modify the way the component behaves.

There are two common ways to provide values to charts during installation:

1. Create YAML files and pass them to Helm using the `-f` or `--values` flag
1. Pass values using the `--set` flag followed by `key=value` pairs

Let's combine these methods to update our UI release. We'll use this `values.yaml` file:

```file
manifests/modules/introduction/helm/values.yaml
```

This adds several custom Kubernetes annotations to the Pods, as well as overriding the UI theme.

:::tip[How do I know what values to use?]

Although many Helm charts have relatively consistent values for configuring common aspects like replicas and Pod annotations, each Helm chart can have its own unique set of configuration. When installing and configuring any given chart you should review its available configuration values via its documentation.

:::

We'll also add additional replicas using the `--set` flag:

```bash hook=replicas
$ helm upgrade ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --set replicaCount=3 \
  --values ~/environment/eks-workshop/modules/introduction/helm/values.yaml \
  --wait
```

List the releases:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                                APP VERSION
ui     ui         2         2024-06-11 04:13:53.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X   X.X.X
```

You'll notice that the **revision** column has updated to **2** as Helm has applied our updated configuration as a distinct revision. This would allow us to rollback to our previous configuration if necessary.

You can view the revision history of a given release like this:

```bash
$ helm history ui -n ui
REVISION  UPDATED                   STATUS      CHART                               APP VERSION  DESCRIPTION
1         Tue Jun 11 03:58:39 2024  superseded  retail-store-sample-ui-chart-X.X.X  X.X.X        Install complete
2         Tue Jun 11 04:13:53 2024  deployed    retail-store-sample-ui-chart-X.X.X  X.X.X        Upgrade complete
```

To check that our changes have taken effect list the Pods in the `ui` namespace:

```bash
$ kubectl get pods -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-4hz9b      1/1     Running   0          30s
ui-55fbd7f494-gkr2j      1/1     Running   0          30s
ui-55fbd7f494-zplwx      1/1     Running   0          5m
```

You can see we now have 3 replicas running. We can also verify our annotation was applied by inspecting the Deployment:

```bash
$ kubectl get -o yaml deployment ui -n ui | yq '.spec.template.metadata.annotations'
my-annotation: my-value
[...]
```

## Removing releases

We can similarly uninstall a release using the CLI:

```bash
$ helm uninstall ui --namespace ui --wait
```

This will delete all the resources created by the chart for that release from our EKS cluster.

Now that you understand how Helm works, proceed to the [Fundamentals module](/docs/fundamentals).
