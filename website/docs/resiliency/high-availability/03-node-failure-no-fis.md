---
title: "Simulating Node Failure without FIS"
sidebar_position: 3
description: "Manually simulate a node failure in your Kubernetes environment to test the resilience of your applications without using AWS FIS."
---

# Simulating Node Failure without FIS

TODO:

- add information and concluding thoughts
- note that this is repeatable
- should see node failure after about a minute, pods come return shortly after to current working nodes, node comes back online after about 2 minutes
- should I make more things following the verify-cluster.sh visual?
- Load balancer does not appear to work although it should
- Rather than the seeing whole script, show expected output?
- Update script to wait for 3 nodes online

## Overview

This experiment simulate a node failure manually in your Kubernetes cluster to understand the impact on your deployed applications, particularly focusing on the retail store application's availability. The `node-failure.sh` script will manually stop an EC2 instance to simulate node failure. Here is the script we will use:

```file
manifests/modules/resiliency/scripts/node-failure.sh
```

To make this script executable:

```bash
$ chmod +x $SCRIPT_DIR/node-failure.sh
```

## Running the Experiment

Run the node failure experiment and monitor the effects on pod distribution:

```bash
$ $SCRIPT_DIR/node-failure.sh && SECONDS=0; while [ $SECONDS -lt 120 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command will stop the selected EC2 instance and monitor the pod distribution for 2 minutes, observing how the system redistributes workloads.

During the experiment, you should observe the following:

- One node disappearing from the list
- Kubernetes will detect the node failure and reschedule the pods that were running on the failed node
- These pods being redistributed to the remaining healthy nodes
- The failed node will come back online

The total number of running pods should remain constant, ensuring application availability.

## Verify Retail Store Availability

After simulating the node failure, verify if the retail store application remains accessible:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

## Verifying Cluster Recovery

After simulating the node failure, we'll verify the cluster's self-healing and potentially rebalance the pod distribution if necessary. Since the cluster often recovers on its own, we'll focus on checking the current state and ensuring an optimal distribution of pods.

Use the following

<!-- [script](/manifests/modules/resiliency/scripts/verify-cluster.sh)  -->

to verify the cluster state and rebalance pods:

```bash
$ chmod +x $SCRIPT_DIR/verify-cluster.sh
$ $SCRIPT_DIR/verify-cluster.sh
```

This script will:

- Counts the number of nodes and ui pods
- Checks if the pods are evenly distributed across the nodes

## Conclusion

add concluding thoughts
