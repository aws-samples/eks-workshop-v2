---
title: "Simulating Partial Node Failure with FIS"
sidebar_position: 4
description: "Simulate a partial node failures in your Kubernetes environment using AWS Fault Injection Simulator to test application resiliency."
---

# Simulating Partial Node Failure with FIS

## AWS Fault Injection Simulator (FIS) Overview

AWS Fault Injection Simulator (FIS) is a fully managed service that enables you to perform controlled fault injection experiments on your AWS workloads. FIS allows you to simulate various failure scenarios, which is crucial for:

1. Validating high availability configurations
2. Testing auto-scaling and self-healing capabilities
3. Identifying potential single points of failure
4. Improving incident response procedures

By using FIS, you can:

- Discover hidden bugs and performance bottlenecks
- Observe how your systems behave under stress
- Implement and validate automated recovery procedures
- Conduct repeatable experiments to ensure consistent behavior

In our FIS experiment, we'll simulate a partial node failure in our EKS cluster and observe how our application responds, providing practical insights into building resilient systems.

:::info
For more information on AWS FIS, check out:

- [What is AWS Fault Injection Service?](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html)
- [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home)
  :::

## Experiment Details

This experiment differs from the previous manual node failure simulation in several ways:

1. Automated execution: FIS manages the experiment, allowing for more controlled and repeatable tests.
2. Partial failure: Instead of simulating a complete node failure, we're testing a scenario where a portion of the nodes fail.
3. Scale: FIS allows us to target multiple nodes simultaneously, providing a more realistic large-scale failure scenario.
4. Precision: We can specify exact percentages of instances to terminate, giving us fine-grained control over the experiment.

In this experiment, FIS will terminate 66% of the instances in two node groups, simulating a significant partial failure of our cluster.

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the partial node failure:

```bash
$ NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"COUNT(2)"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"66"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the node failure and monitor the response:

```bash
$ aws fis start-experiment --experiment-template-id $NODE_EXP_ID --output json && SECONDS=0; while [ $SECONDS -lt 180 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command triggers the node failure and monitors the pods for 3 minutes, allowing you to observe how the cluster responds to losing a significant portion of its capacity.

During the experiment, you should observe the following:

1. After about 1 minute, you'll see one or more nodes disappear from the list, representing the simulated partial node failure.
2. Over the next 2 minutes, you'll notice pods being rescheduled and redistributed to the remaining healthy nodes.
3. Shortly after you'll see the new node coming online to replace the terminated one.

Your retail url should stay operational unlike the node failure without FIS.

:::note
To verify clusters and rebalance pods, you can run:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

:::

## Verifying Retail Store Availability

Ensure that your retail store application remains operational throughout the partial node failure. Use the following command to check its availability:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::tip
The retail url may take 10 minutes to become operational.
:::

Despite the partial node failure, the retail store should continue to serve traffic, demonstrating the resilience of your deployment setup.

:::caution
Partial node failures test the limits of your application's failover capabilities. Monitor and determine how well your applications and services recover from such events.
:::

## Conclusion

This partial node failure simulation using AWS FIS demonstrates several key aspects of your Kubernetes cluster's resilience:

1. Automatic detection of node failures by Kubernetes
2. Swift rescheduling of pods from failed nodes to healthy ones
3. The cluster's ability to maintain service availability during significant infrastructure disruptions
4. Auto-scaling capabilities to replace failed nodes

Key takeaways from this experiment:

- The importance of distributing your workload across multiple nodes and availability zones
- The value of having appropriate resource requests and limits set for your pods
- The effectiveness of Kubernetes' self-healing mechanisms
- The need for robust monitoring and alerting systems to detect and respond to node failures

By leveraging AWS FIS for such experiments, you gain several advantages:

1. Repeatability: You can run this experiment multiple times to ensure consistent behavior.
2. Automation: FIS allows you to schedule regular resilience tests, ensuring your system maintains its fault-tolerant capabilities over time.
3. Comprehensive testing: You can create more complex scenarios involving multiple AWS services to test your entire application stack.
4. Controlled chaos: FIS provides a safe, managed environment for conducting chaos engineering experiments without risking unintended damage to your production systems.

Regular execution of such experiments helps build confidence in your system's resilience and provides valuable insights for continuous improvement of your architecture and operational procedures.
