---
title: "Lab Setup: Chaos Mesh, Scaling, and Pod affinity"
sidebar_position: 90
description: "Learn how to scale your pods, add Pod Anti-Affinity configurations, and use a helper script to visualize pod distribution."
---

This guide outlines steps to enhance the resilience of a UI service by implementing high availability practices. We'll cover installing helm, scaling the UI service, implementing pod anti-affinity, and using a helper script to visualize pod distribution across availability zones.

## Installing Chaos Mesh

To enhance our cluster's resilience testing capabilities, we'll install Chaos Mesh. Chaos Mesh is a powerful chaos engineering tool for Kubernetes environments. It allows us to simulate various failure scenarios and test how our applications respond.

Let's install Chaos Mesh in our cluster using Helm:

```bash timeout=240
$ helm repo add chaos-mesh https://charts.chaos-mesh.org
$ helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --version 2.5.1 \
  --set dashboard.create=true \
  --wait

Release "chaos-mesh" does not exist. Installing it now.
NAME: chaos-mesh
LAST DEPLOYED: Tue Aug 20 04:44:31 2024
NAMESPACE: chaos-mesh
STATUS: deployed
REVISION: 1
TEST SUITE: None

```

## Scaling and Topology Spread Constraints

We use a Kustomize patch to modify the UI deployment, scaling it to 5 replicas and adding topology spread constraints rules. This ensures UI pods are distributed across different nodes, reducing the impact of node failures.

Here's the content of our patch file:

```kustomization
modules/observability/resiliency/high-availability/config/scale_and_affinity_patch.yaml
Deployment/ui
```

Apply the changes using Kustomize patch and
[Kustomization file](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/high-availability/config/kustomization.yaml):

```bash timeout=120
$ kubectl delete deployment ui -n ui
$ kubectl apply -k ~/environment/eks-workshop/modules/observability/resiliency/high-availability/config/
```

## Verify Retail Store Accessibility

After applying these changes, it's important to verify that your retail store is accessible:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

Once this command completes, it will output a URL. Open this URL in a new browser tab to verify that your retail store is accessible and functioning correctly.

:::tip
The retail url may take 5-10 minutes to become operational.
:::

## Helper Script: Get Pods by AZ

The `get-pods-by-az.sh` script helps visualize the distribution of Kubernetes pods across different availability zones in the terminal. You can view the script file on github [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/scripts/get-pods-by-az.sh).

### Script Execution

To run the script and see the distribution of pods across availability zones, execute:

```bash
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-6fzrk   1/1   Running   0     56s
       ui-6dfb84cf67-dsp55   1/1   Running   0     56s

------us-west-2b------
  ip-10-42-153-179.us-west-2.compute.internal:
       ui-6dfb84cf67-2pxnp   1/1   Running   0     59s

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-n8x4f   1/1   Running   0     61s
       ui-6dfb84cf67-wljth   1/1   Running   0     61s

```

:::info
For more information on these changes, check out these sections:

- [Chaos Mesh](https://chaos-mesh.org/)
- [Pod Affinity and Anti-Affinity](/docs/fundamentals/compute/managed-node-groups/basics/affinity/)

:::
