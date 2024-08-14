---
title: "Simulating Complete Node Failure with FIS"
sidebar_position: 5
description: "Demonstrates the impact of a complete node failure on a Kubernetes environment using AWS Fault Injection Simulator."
---

# Simulating Complete Node Failure with FIS

TODO:

- Fix script to mimic last experiment again
- Why is this different than last experiment
- Explain what is happening in more detail
- Note timings
- Concluding Statement
- You should see all nodes and pods dissapear rather quickly then after about 2 minutes will start to see 1 node and pods coming online, after 4 minutes a second node will come online and 3 more pods.

## Overview

This experiment is an extensive test that isn't necessary but demonstrates the robust capabilities of AWS Fault Injection Simulator by simulating a complete node failure in a Kubernetes cluster.

:::info Important
This test showcases how FIS can be used to simulate worst-case scenarios to help validate the resilience and recovery strategies of your applications.
:::

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the complete failure of all nodes in a specific node group:

```bash
$ FULL_NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"ALL"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"100"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the complete node failure:

```bash
$ aws fis start-experiment --experiment-template-id $FULL_NODE_EXP_ID --output json && SECONDS=0; while [ $SECONDS -lt 300 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

Monitor the cluster as it loses all node resources temporarily, observing how the Kubernetes system and your application respond.

## Verifying Retail Store Availability

After simulating the node failure, check if the retail store application is still operational:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

This command helps confirm that despite complete node failure, the application begins to recover as the Kubernetes cluster auto-scales back up.

:::caution
This test can cause significant disruption, so it's recommended for use only in controlled environments where recovery mechanisms are thoroughly tested.
:::

:::note
To verify clusters and rebalance pods you can run:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

:::
