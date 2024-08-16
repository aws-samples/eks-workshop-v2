---
title: "Simulating Complete Node Failure with FIS"
sidebar_position: 5
description: "Demonstrates the impact of a complete node failure on a Kubernetes environment using AWS Fault Injection Simulator."
---

# Simulating Complete Node Failure with FIS

## Overview

This experiment extends our previous partial node failure test to simulate a complete failure of all nodes in our EKS cluster. It demonstrates how AWS Fault Injection Simulator (FIS) can be used to test extreme scenarios and validate your system's resilience under catastrophic conditions.

:::info Important
This test simulates a worst-case scenario. It's designed for controlled environments with thoroughly tested recovery mechanisms.
:::

## Experiment Details

Unlike the partial node failure simulation, this experiment:

1. Terminates 100% of the instances in all node groups.
2. Tests your cluster's ability to recover from a state of complete failure.
3. Allows observation of the full recovery process, from total outage to full restoration.

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the complete node failure:

```bash
$ FULL_NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"ALL"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"100"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment and monitor the cluster's response:

```bash
$ aws fis start-experiment --experiment-template-id $FULL_NODE_EXP_ID --output json && SECONDS=0; while [ $SECONDS -lt 300 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command will show the pods distribution over 5 minutes while we observe the experiment. We should see:

1. Shortly after the experment is initiated, all nodes and pods dissapear.
2. After about 2 minutes, First node and some pods will come back online.
3. Around 4 minutes, a second node appears and more pods start up.
4. At 5 minutes, continued recovery as the last node come online.

Due to the severity of the experiment, the retail store url will not stay operational during testing. The url should come back up after the final node is operational.

:::note
To verify clusters and rebalance pods, you can run:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

:::

## Verifying Retail Store Availability

Check the retail store application's recovery:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::tip
The retail url may take 10 minutes to become operational.
:::

## Conclusion

This experiment demonstrates:

1. Your cluster's response to catastrophic failure.
2. Effectiveness of auto-scaling in replacing all failed nodes.
3. Kubernetes' ability to reschedule all pods onto new nodes.
4. Total system recovery time from complete failure.

Key learnings:

- Importance of robust auto-scaling configurations.
- Value of effective pod priority and preemption settings.
- Need for architectures that can withstand complete cluster failure.
- Significance of regular testing of extreme scenarios.

By using FIS for such tests, you can safely simulate catastrophic failures, validate recovery procedures, identify critical dependencies, and measure recovery times. This helps in refining your disaster recovery plans and improving overall system resilience.
