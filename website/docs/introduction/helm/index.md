---
title: Helm
sidebar_custom_props: { "module": true }
sidebar_position: 69
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=10
$ prepare-environment introduction/helm
```

:::

Although we will primarily be interacting with kustomize in this workshop, there will be situations where Helm will be used to install certain packages in the EKS cluster. In this lab we give a brief introduction to Helm, and we'll demonstrate how to use it to install a pre-packaged application.

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

## Helm repositories

A Helm repository is a centralized location where Helm charts are stored and managed, and allow users to easily discover, share, and install charts. They facilitate easy access to a wide range of pre-packaged applications and services for deployment on Kubernetes clusters.

The [Bitnami](https://github.com/bitnami/charts) Helm repository is a collection of Helm charts for deploying popular applications and tools on Kubernetes. Let's add the `bitnami` repository to our Helm CLI:

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm repo update
```

Now we can search the repository for charts, for example the `nginx` chart:

```bash
$ helm search repo nginx
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
bitnami/nginx           X.X.X           X.X.X           NGINX Open Source is a web server that can be a...
[...]
```

## Installing a Helm chart

Let's install an NGINX server in our EKS cluster using the Helm chart we found above. When you install a chart using the Helm package manager, it creates a new **release** for that chart. Each release is tracked by Helm and can be upgraded, rolled back, or uninstalled independently from other releases.

```bash hook=install
$ echo $NGINX_CHART_VERSION
$ helm install nginx bitnami/nginx \
  --version $NGINX_CHART_VERSION \
  --namespace nginx --create-namespace --wait
```

We can break this command down as follows:

- Use the `install` sub-command to instruct Helm to install a chart
- Name the release `nginx`
- Use the chart `bitnami/nginx` with the version $NGINX_CHART_VERSION
- Install the chart in the `nginx` namespace and create that namespace first
- Wait for pods in the release to get to a ready state

Once the chart has installed we can list the releases in our EKS cluster:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART         APP VERSION
nginx  nginx      1         2024-06-11 03:58:39.862100855 +0000 UTC  deployed  nginx-X.X.X   X.X.X
```

We can also see NGINX running in the namespace we specified:

```bash
$ kubectl get pod -n nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-55fbd7f494-zplwx   1/1     Running   0          119s
```

## Configuring chart options

In the example above we installed the NGINX chart in its default configuration. Sometimes you'll need to provide configuration **values** to charts during installation to modify the way the component behaves.

There are two common ways to provide values to charts during installation:

1. Create YAML files and pass them to Helm using the `-f` or `--values` flag
1. Pass values using the `--set` flag followed by `key=value` pairs

Let's combine these methods to update our NGINX release. We'll use this `values.yaml` file:

```file
manifests/modules/introduction/helm/values.yaml
```

This adds several custom Kubernetes labels to the NGINX pods, as well as setting some resource requests.

We'll also add additional replicas using the `--set` flag:

```bash hook=replicas
$ helm upgrade --install nginx bitnami/nginx \
  --version $NGINX_CHART_VERSION \
  --namespace nginx --create-namespace --wait \
  --set replicaCount=3 \
  --values ~/environment/eks-workshop/modules/introduction/helm/values.yaml \
  --wait
```

List the releases:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART         APP VERSION
nginx  nginx      2         2024-06-11 04:13:53.862100855 +0000 UTC  deployed  nginx-X.X.X   X.X.X
```

You'll notice that the **revision** column has updated to **2** as Helm has applied our updated configuration as a distinct revision. This would allow us to rollback to our previous configuration if necessary.

You can view the revision history of a given release like this:

```bash
$ helm history nginx -n nginx
REVISION  UPDATED                   STATUS      CHART        APP VERSION  DESCRIPTION
1         Tue Jun 11 03:58:39 2024  superseded  nginx-X.X.X  X.X.X       Install complete
2         Tue Jun 11 04:13:53 2024  deployed    nginx-X.X.X  X.X.X       Upgrade complete
```

To check that our changes have taken effect list the pods in the `nginx` namespace:

```bash
$ kubectl get pods -n nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-55fbd7f494-4hz9b   1/1     Running   0          30s
nginx-55fbd7f494-gkr2j   1/1     Running   0          30s
nginx-55fbd7f494-zplwx   1/1     Running   0          5m
```

You can see we now have 3 replicas of the NGINX pod running.

## Removing releases

We can similarly uninstall a release using the CLI:

```bash
$ helm uninstall nginx --namespace nginx --wait
```

This will delete all the resources created by the chart for that release from our EKS cluster.

## Deploying Applications with Helm

Now let's see how Helm can be used to deploy our retail store application. While the workshop primarily uses Kustomize, understanding Helm is valuable as many third-party applications are distributed as Helm charts.

### Creating a Simple Chart for the Catalog Service

Let's create a basic Helm chart for our catalog service to understand how applications can be packaged and deployed with Helm:

```bash
$ helm create retail-catalog
```

This creates a basic chart structure. Let's examine what was created:

```bash
$ ls -la retail-catalog/
total 8
drwxr-xr-x  4 user user  128 Nov 15 10:30 .
drwxr-xr-x  3 user user   96 Nov 15 10:30 ..
-rw-r--r--  1 user user 1141 Nov 15 10:30 Chart.yaml
drwxr-xr-x  2 user user   64 Nov 15 10:30 charts
drwxr-xr-x  3 user user   96 Nov 15 10:30 templates
-rw-r--r--  1 user user 1862 Nov 15 10:30 values.yaml
```

### Customizing the Chart

Let's modify the default values to deploy our catalog service. Update the `values.yaml` file:

```bash
$ cat > retail-catalog/values.yaml << 'EOF'
replicaCount: 2

image:
  repository: public.ecr.aws/aws-containers/retail-store-sample-catalog
  tag: "0.4.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

resources:
  requests:
    cpu: 128m
    memory: 512Mi
  limits:
    cpu: 256m
    memory: 512Mi

nameOverride: "catalog"
fullnameOverride: "catalog"
EOF
```

### Installing the Chart

Now let's install our catalog service using the Helm chart:

```bash
$ helm install catalog ./retail-catalog --namespace catalog --create-namespace
```

Verify the deployment:

```bash
$ helm list -n catalog
NAME     NAMESPACE  REVISION  UPDATED                                  STATUS    CHART               APP VERSION
catalog  catalog    1         2024-11-15 10:35:42.123456789 +0000 UTC  deployed  retail-catalog-0.1.0  1.16.0
```

Check the running pods:

```bash
$ kubectl get pods -n catalog
NAME                       READY   STATUS    RESTARTS   AGE
catalog-7d4b8c9f8d-abc12   1/1     Running   0          2m
catalog-7d4b8c9f8d-def34   1/1     Running   0          2m
```

### Upgrading the Release

One of Helm's strengths is managing application upgrades. Let's scale our application by updating the replica count:

```bash
$ helm upgrade catalog ./retail-catalog \
  --namespace catalog \
  --set replicaCount=3
```

### Rolling Back

If something goes wrong, Helm makes it easy to rollback:

```bash
$ helm rollback catalog 1 -n catalog
```

### Cleaning Up

Remove the Helm release:

```bash
$ helm uninstall catalog -n catalog
```

This example shows how Helm provides a higher-level abstraction for deploying applications, with built-in support for upgrades, rollbacks, and configuration management.

Now that you understand how Helm works, you can proceed to [Kustomize](../kustomize) to learn about declarative configuration management, or jump ahead to the [Fundamentals module](/docs/fundamentals).
