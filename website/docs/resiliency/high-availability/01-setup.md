---
title: "Scaling and Pod Anti-Affinity for UI Service"
sidebar_position: 1
description: "Learn how to scale your pods, add Pod Anti-Affinity configurations, and use a helper script to visualize pod distribution."
---

This guide outlines steps to enhance the resilience of a UI service by implementing high availability practices. We'll cover scaling the UI service, implementing pod anti-affinity, and using a helper script to visualize pod distribution across availability zones.

## Scaling and Pod Anti-Affinity

We use a Kustomize patch to modify the UI deployment, scaling it to 5 replicas and adding pod anti-affinity rules. This ensures UI pods are distributed across different nodes, reducing the impact of node failures.

Here's the content of our patch file:

```file
manifests/modules/resiliency/high-availability/config/scale_and_affinity_patch.yaml
```

Apply the changes using Kustomize patch and
[Kustomization file](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/high-availability/config/kustomization.yaml):

```bash
$ kubectl delete deployment ui -n ui
$ kubectl apply -k /manifests/modules/resiliency/high-availability/config/
```

## Verify Retail Store Accessibility

After applying these changes, it's important to verify that your retail store is accessible:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

Once this command completes, it will output a URL. Open this URL in a new browser tab to verify that your retail store is accessible and functioning correctly.

:::tip
If the retail store doesn't load immediately, wait a few moments and refresh the page. It may take a short time for all components to become fully operational.
:::

## Helper Script: Get Pods by AZ

The `get-pods-by-az.sh` script helps visualize the distribution of Kubernetes pods across different availability zones in the terminal. You can view the script file on github [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/scripts/get-pods-by-az.sh).

### Script Execution

To run the script and see the distribution of pods across availability zones, execute:

```bash
$ $SCRIPT_DIR/get-pods-by-az.sh
```

:::tip
Use this to quickly assess the distribution of your pods across multiple zones.
:::

:::info
For more information on these changes, check out these sections:

- [Pod Affinity and Anti-Affinity](/docs/fundamentals/managed-node-groups/basics/affinity/)
  :::
