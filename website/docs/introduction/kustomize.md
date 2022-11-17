---
title: Kustomize (optional)
sidebar_position: 40
---

Kustomize allows you to patch Kubernetes manifest files using declarative "kustomization" file. It is integrated directly with the `kubectl` CLI, and can be applied with `kubectl apply -k <kustomization_directory>`. This approach is used through this workshop to make it easier to apply changes to manifest files, while clearly surfacing the changes to be applied.

For example, take a look at the following manifest file for the `checkout` deployment:

```file
../manifests/checkout/deployment.yaml
```

This file has already been applied in the previous [Getting Started](getting-started/deploy) lab, but let's say we wanted to update the `replicas` field using `kustomize`. Rather than manually updating this YAML file, we will use Kustomize to update the `spec/replicas` field from 1 to 2.

To do so, we'll apply the following kustomization file. The first tab shows the kustomization file itself. The second tab shows a preview of what the updated `Deployment/checkout` file looks like after the kustomization is applied. Finally, the third tab shows just the diff of what has changed.

```kustomization
introduction/kustomize/deployment.yaml
Deployment/checkout
```

To apply this kustomization, run the following command:

```bash
$ kubectl apply -k /workspace/modules/introduction/kustomize/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
```

You'll notice that a number of different `checkout`-related resources are "unchanged", with the `deployment.apps/checkout` being "configured". This is intentional—we only want to apply changes to the `checkout` deployment. This happens because running the previous command actually applied two files: the Kustomize `deployment.yaml` that we saw above, as well as the following `kustomization.yaml` file which matches all files in the `manifests/checkout` folder. The `patches` field specifies the specific file to be patched:

```file
introduction/kustomize/kustomization.yaml
```

To check that the number of replicas has been updated, run the following command:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

To reset any kustomizations, you can simply apply the original set of manifests:

```bash timeout=300 wait=30
$ kubectl apply -k /workspace/manifests
```

Now that you understand how Kustomize works, proceed to the [Fundamentals module](/docs/fundamentals).