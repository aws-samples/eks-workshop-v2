---
title: Kustomize
sidebar_custom_props: { "module": true }
sidebar_position: 70
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment
```

:::

[Kustomize](https://kustomize.io/) allows you to manage Kubernetes manifest files using declarative "kustomization" files. It provides the ability to express "base" manifests for your Kubernetes resources and then apply changes using composition, customization and easily making cross-cutting changes across many resources.

## Deploying the Retail Store Application

Let's start by deploying the complete retail store application using Kustomize. The application consists of multiple microservices that work together:

### Deploy the Base Application

First, let's deploy the entire retail store application using the base configuration:

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

This single command deploys all the microservices. Let's see what was created:

```bash
$ kubectl get pods -A -l app.kubernetes.io/created-by=eks-workshop
NAME                               READY   STATUS    RESTARTS   AGE
cart-6d4f8c9b8d-xyz12             1/1     Running   0          2m
catalog-7b5c9d8e9f-abc34          1/1     Running   0          2m
checkout-8c6d0e1f2g-def56         1/1     Running   0          2m
orders-9d7e2f3g4h-ghi78          1/1     Running   0          2m
ui-0e8f3g4h5i-jkl90              1/1     Running   0          2m
```

### Understanding the Kustomization Structure

The base application uses a `kustomization.yaml` file that references all the component directories:

```bash
$ cat ~/environment/eks-workshop/base-application/kustomization.yaml
```

Each service has its own directory with Kubernetes manifests:

```bash
$ ls ~/environment/eks-workshop/base-application/
cart/  catalog/  checkout/  orders/  ui/  kustomization.yaml
```

### Customizing with Overlays

Now let's see Kustomize's power by creating customizations. For example, let's scale the `checkout` service horizontally by updating the `replicas` field from 1 to 3.

Take a look at the following manifest file for the `checkout` Deployment:

```file
manifests/base-application/checkout/deployment.yaml
```

Rather than manually updating this YAML file, we'll use Kustomize to update the `spec/replicas` field from 1 to 3.

To do so, we'll apply the following kustomization.

- The first tab shows the kustomization we're applying
- The second tab shows a preview of what the updated `Deployment/checkout` file looks like after the kustomization is applied
- Finally, the third tab shows just the diff of what has changed

```kustomization
modules/introduction/kustomize/deployment.yaml
Deployment/checkout
```

You can generate the final Kubernetes YAML that applies this kustomization with the `kubectl kustomize` command, which invokes `kustomize` that is bundled with the `kubectl` CLI:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize
```

This will generate a lot of YAML files, which represents the final manifests you can apply directly to Kubernetes. Let's demonstrate this by piping the output from `kustomize` directly to `kubectl apply`:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize | kubectl apply -f -
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
```

You'll notice that a number of different `checkout`-related resources are "unchanged", with the `deployment.apps/checkout` being "configured". This is intentional — we only want to apply changes to the `checkout` deployment. This happens because running the previous command actually applied two files: the Kustomize `deployment.yaml` that we saw above, as well as the following `kustomization.yaml` file which matches all files in the `~/environment/eks-workshop/base-application/checkout` folder. The `patches` field specifies the specific file to be patched:

```file
manifests/modules/introduction/kustomize/kustomization.yaml
```

To check that the number of replicas has been updated, run the following command:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-b2rrz   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

Instead of using the combination of `kubectl kustomize` and `kubectl apply` we can instead accomplish the same thing with `kubectl apply -k <kustomization_directory>` (note the `-k` flag instead of `-f`). This approach is used through this workshop to make it easier to apply changes to manifest files, while clearly surfacing the changes to be applied.

Let's try that:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/kustomize
```

To reset the application manifests back to their initial state, you can simply apply the original set of manifests:

```bash timeout=300 wait=30
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

Another pattern you will see used in some lab exercises looks like this:

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application \
  | envsubst | kubectl apply -f-
```

This uses `envsubst` to substitute environment variable placeholders in the Kubernetes manifest files with the actual values based on your particular environment. For example in some manifests we need to reference the EKS cluster name with `$EKS_CLUSTER_NAME` or the AWS region with `$AWS_REGION`.

## Advanced Kustomize Patterns

### Environment-Specific Configurations

Kustomize excels at managing different configurations for different environments. You might have:

- **Base**: Common configuration shared across all environments
- **Development Overlay**: Lower resource limits, debug logging enabled
- **Production Overlay**: Higher resource limits, multiple replicas, monitoring enabled

### Cross-Cutting Changes

One of Kustomize's strengths is making changes across multiple resources. For example, you could:

- Add labels to all resources: `commonLabels`
- Add annotations to all resources: `commonAnnotations`
- Set resource limits across all deployments
- Configure image pull policies consistently

### Deploying Individual Services

You can also deploy individual services using their specific kustomization:

```bash
# Deploy just the catalog service
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog

# Deploy just the UI service  
$ kubectl apply -k ~/environment/eks-workshop/base-application/ui
```

### Viewing Generated Manifests

Before applying changes, you can preview what Kustomize will generate:

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application/catalog
```

This shows you exactly what Kubernetes resources will be created without actually applying them to the cluster.

Now that you understand how Kustomize works, you can proceed to the [Getting Started](/docs/introduction/getting-started) hands-on lab or go directly to the [Fundamentals module](/docs/fundamentals).

To learn more about Kustomize, you can refer to the official Kubernetes [documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).
