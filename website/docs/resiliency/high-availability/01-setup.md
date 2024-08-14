---
title: "Scaling and Pod Anti-Affinity for UI Service"
sidebar_position: 1
description: "Learn how to scale your pods, add Pod Anti-Affinity configurations, and use a helper script to visualize pod distribution."
---

TODO:

- Update Name
- Update/Remove Verification

This guide outlines steps to enhance the resilience of a UI service by implementing high availability practices. We'll cover scaling the UI service, implementing pod anti-affinity, and using a helper script to visualize pod distribution across availability zones.

## Scaling and Pod Anti-Affinity

We use a Kustomize patch to modify the UI deployment, scaling it to 5 replicas and adding pod anti-affinity rules. This ensures UI pods are distributed across different nodes, reducing the impact of node failures.

Here's the content of our patch file:

```file
manifests/modules/resiliency/high-availability/config/scale_and_affinity_patch.yaml
```

Apply the changes using Kustomize patch and 

<!-- [Kustomization file](manifests/modules/resiliency/high-availability/config/kustomization.yaml): -->

```bash
$ kubectl delete deployment ui -n ui
$ kubectl apply -k /manifests/modules/resiliency/high-availability/config/
```

## Create Helper Script: Get Pods by AZ

The `get-pods-by-az.sh` script helps visualize the distribution of Kubernetes pods across different availability zones in the terminal. You can view the script file

<!-- [here](manifests/modules/resiliency/scripts/get-pods-by-az.sh) -->

To make this script executable:

```bash
$ chmod +x $SCRIPT_DIR/get-pods-by-az.sh
```

### Script Execution

To run the script and see the distribution of pods across availability zones, execute:

```bash
$ $SCRIPT_DIR/get-pods-by-az.sh
```

:::tip
Use this to quickly assess the distribution of your pods across multiple zones.
:::

## Verification

After applying these changes, verify the setup:

1. Check for 5 running UI pods:

```bash
$ kubectl get pods -n ui
```

2. Verify pod distribution across nodes:

```bash
$ kubectl get pods -n ui -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
```

3. Check that AWS Load Balancer Controller is installed and working:

```bash
$ kubectl get pods -n kube-system | grep aws-load-balancer-controller
$ kubectl get ingress --all-namespaces
```

4. Ensure the Load Balancer is working and access to the Retail URL:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::info
For more information on these changes, check out these sections:

- [Pod Affinity and Anti-Affinity](/docs/fundamentals/managed-node-groups/basics/affinity/)
  :::
