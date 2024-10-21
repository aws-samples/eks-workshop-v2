---
title: "Simulating Node Failure without FIS"
sidebar_position: 130
description: "Manually simulate a node failure in your Kubernetes environment to test the resilience of your applications without using AWS FIS."
---

## Overview

This experiment simulates a node failure manually in your Kubernetes cluster to understand the impact on your deployed applications, particularly focusing on the retail store application's availability. By deliberately causing a node to fail, we can observe how Kubernetes handles the failure and maintains the overall health of the cluster.

The `node-failure.sh` script will manually stop an EC2 instance to simulate node failure. Here is the script we will use:

```file
manifests/modules/observability/resiliency/scripts/node-failure.sh
```

It's important to note that this experiment is repeatable, allowing you to run it multiple times to ensure consistent behavior and to test various scenarios or configurations.

## Running the Experiment

To simulate the node failure and monitor its effects, run the following command:

```bash timeout=240 
$ ~/$SCRIPT_DIR/node-failure.sh && timeout --preserve-status 180s  ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-dsp55   1/1   Running   0     10m
       ui-6dfb84cf67-gzd9s   1/1   Running   0     8m19s

------us-west-2b------
  ip-10-42-133-195.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-4bmjm   1/1   Running   0     44s
       ui-6dfb84cf67-n8x4f   1/1   Running   0     10m
       ui-6dfb84cf67-wljth   1/1   Running   0     10m
```

This command will stop the selected EC2 instance and monitor the pod distribution for 2 minutes, observing how the system redistributes workloads.

During the experiment, you should observe the following sequence of events:

1. After about 1 minute, you'll see one node disappear from the list. This represents the simulated node failure.
2. Shortly after the node failure, you'll notice pods being redistributed to the remaining healthy nodes. Kubernetes detects the node failure and automatically reschedules the affected pods.
3. Approximately 2 minutes after the initial failure, the failed node will come back online.

Throughout this process, the total number of running pods should remain constant, ensuring application availability.

## Verifying Cluster Recovery

While waiting for the node to finish coming back online, we will verify the cluster's self-healing capabilities and potentially recycle pods again if necessary. Since the cluster often recovers on its own, we'll focus on checking the current state and ensuring an optimal distribution of pods across AZs.

First let's ensure all nodes are in the `Ready` state:

```bash timeout=300
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
```

This command counts the total number of nodes in the `Ready` state and continuously checks until all 3 active nodes are ready.

Once all nodes are ready, we'll redeploy the pods to ensure they are balanced across the nodes:

```bash timeout=900 wait=30
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=dynamodb
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=redis
$ kubectl delete pod --grace-period=0 --force -n assets -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n ui -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=service
$ sleep 90
$ kubectl rollout status -n ui deployment/ui --timeout 180s
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30
```

These commands perform the following actions:

1. Delete the existing ui pods.
2. Wait for ui pods to be provisioned automatically.
3. Use the `get-pods-by-az.sh` script to check the distribution of pods across availability zones.

## Verify Retail Store Availability

After simulating the node failure, we can verify that the retail store application remains accessible. Use the following command to check its availability:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

This command retrieves the load balancer hostname for the ingress and waits for it to become available. Once ready, you can access the retail store through this URL to confirm that it's still functioning correctly despite the simulated node failure.

:::caution
The retail url may take 10 minutes to become operational. You can optionally continue on with the lab by pressing `ctrl` + `z` to move operation to the background. To access it again input:

```bash test=false
$ fg %1
```

The url may not become operational by the time `wait-for-lb` times out. In that case, it should become operational after running the command again:

```bash test=false
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::

## Conclusion

This node failure simulation demonstrates the robustness and self-healing capabilities of your Kubernetes cluster. Key observations and lessons from this experiment include:

1. Kubernetes' ability to quickly detect node failures and respond accordingly.
2. The automatic rescheduling of pods from the failed node to healthy nodes, ensuring continuity of service.
3. The EKS cluster's self-healing process using EKS manged node group, brings the failed node back online after a short period.
4. The importance of proper resource allocation and pod distribution to maintain application availability during node failures.

By regularly performing such experiments, you can:

- Validate your cluster's resilience to node failures.
- Identify potential weaknesses in your application's architecture or deployment strategy.
- Gain confidence in your system's ability to handle unexpected infrastructure issues.
- Refine your incident response procedures and automation.
