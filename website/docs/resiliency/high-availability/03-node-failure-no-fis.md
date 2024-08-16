---
title: "Simulating Node Failure without FIS"
sidebar_position: 3
description: "Manually simulate a node failure in your Kubernetes environment to test the resilience of your applications without using AWS FIS."
---

# Simulating Node Failure without FIS

## Overview

This experiment simulates a node failure manually in your Kubernetes cluster to understand the impact on your deployed applications, particularly focusing on the retail store application's availability. By deliberately causing a node to fail, we can observe how Kubernetes handles the failure and maintains the overall health of the cluster.

The `node-failure.sh` script will manually stop an EC2 instance to simulate node failure. Here is the script we will use:

```file
manifests/modules/resiliency/scripts/node-failure.sh
```

It's important to note that this experiment is repeatable, allowing you to run it multiple times to ensure consistent behavior and to test various scenarios or configurations.

## Running the Experiment

To simulate the node failure and monitor its effects, run the following command:

```bash
$ $SCRIPT_DIR/node-failure.sh && SECONDS=0; while [ $SECONDS -lt 120 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command will stop the selected EC2 instance and monitor the pod distribution for 2 minutes, observing how the system redistributes workloads.

During the experiment, you should observe the following sequence of events:

1. After about 1 minute, you'll see one node disappear from the list. This represents the simulated node failure.
2. Shortly after the node failure, you'll notice pods being redistributed to the remaining healthy nodes. Kubernetes detects the node failure and automatically reschedules the affected pods.
3. Approximately 2 minutes after the initial failure, the failed node will come back online.

Throughout this process, the total number of running pods should remain constant, ensuring application availability.

## Verifying Cluster Recovery

While waiting for the node to finish coming back online, we will verify the cluster's self-healing capabilities and potentially rebalance the pod distribution if necessary. Since the cluster often recovers on its own, we'll focus on checking the current state and ensuring an optimal distribution of pods.

Use the following [script](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/scripts/verify-cluster.sh) to verify the cluster state and rebalance pods:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

This script will:

- Wait for nodes to come back online
- Count the number of nodes and ui pods
- Check if the pods are evenly distributed across the nodes

## Verify Retail Store Availability

After simulating the node failure, we can verify that the retail store application remains accessible. Use the following command to check its availability:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

This command retrieves the load balancer hostname for the ingress and waits for it to become available. Once ready, you can access the retail store through this URL to confirm that it's still functioning correctly despite the simulated node failure.

:::caution
The retail url may take 10 minutes to become operational. You can optionally continue on with the lab by pressing `ctrl` + `z` to move operation to the background. To access it again input:

```bash
$ fg
```

The url may not become operational by the time `wait-for-lb` times out. In that case, it should become operational after running the command again:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::

## Conclusion

This node failure simulation demonstrates the robustness and self-healing capabilities of your Kubernetes cluster. Key observations and lessons from this experiment include:

1. Kubernetes' ability to quickly detect node failures and respond accordingly.
2. The automatic rescheduling of pods from the failed node to healthy nodes, ensuring continuity of service.
3. The cluster's self-healing process, bringing the failed node back online after a short period.
4. The importance of proper resource allocation and pod distribution to maintain application availability during node failures.

By regularly performing such experiments, you can:

- Validate your cluster's resilience to node failures.
- Identify potential weaknesses in your application's architecture or deployment strategy.
- Gain confidence in your system's ability to handle unexpected infrastructure issues.
- Refine your incident response procedures and automation.
