---
title: "Simulating Partial Node Failure with FIS"
sidebar_position: 4
description: "Simulate a partial node failures in your Kubernetes environment using AWS Fault Injection Simulator to test application resiliency."
---

# Simulating Partial Node Failure with FIS

TODO:

- More FIS info?
- More information about the experiment
- Explain what FIS is doing different, what the experiment is doing
- should see a 1 node failing after about a minute, pods to come back up after 2 and a half minutes, and the node come back up after
- check to make sure retail app stays up
- retail app apears to not work -> need to fix load balancer configs
- A conclusion / learning from experiment
- Note that FIS can allow automatic testing for failure and whatever else is cool

## AWS Fault Injection Simulator (FIS) Overview

AWS Fault Injection Simulator is a fully managed service that helps you perform fault injection experiments on your AWS workloads. In the context of EKS, FIS allows us to simulate various failure scenarios, which is crucial for:

1. Validating high availability configurations
2. Testing auto-scaling and self-healing capabilities
3. Identifying potential single points of failure
4. Improving incident response procedures

By using FIS, you can:

- Discover hidden bugs and performance bottlenecks
- Observe how your systems behave under stress
- Implement and validate automated recovery procedures

In our FIS experiment, we'll simulate a partial node failure in our EKS cluster and observe how our application responds, providing practical insights into building resilient systems.

:::info
For more information on AWS FIS check out:

- [What is AWS Fault Injection Service?](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html)
  :::

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the node failure:

```bash
$ NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"COUNT(2)"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"66"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the node failure and monitor the response:

```bash
$ aws fis start-experiment --experiment-template-id $NODE_EXP_ID --output json && SECONDS=0; while [ $SECONDS -lt 300 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This will trigger the node failure and begin monitoring the pods for 5 minutes, observing how the cluster responds to losing part of its capacity.

## Verifying Retail Store Availability

After simulating the node failure, check if the retail store application remains operational:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

Despite a partial node failure, the retail store continues to serve traffic, demonstrating the resilience of your deployment setup.

:::caution
Partial node failures test the limits of your application's failover capabilities. Monitor and determine how well your applications and services recover from such events.
:::

:::note
To verify clusters and rebalance pods you can run:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

:::
