---
title: "Simulating Partial Node Failure with FIS"
sidebar_position: 150
description: "Simulate a partial node failures in your Kubernetes environment using AWS Fault Injection Simulator to test application resiliency."
---

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
- [AWS Systems Manager, Automation](https://console.aws.amazon.com/systems-manager/automation/executions)

:::

## Experiment Details

This experiment differs from the previous manual node failure simulation in several ways:

1. **Automated execution**: FIS manages the experiment, allowing for more controlled and repeatable tests compared to the manual script execution in the previous experiment.
2. **Partial failure**: Instead of simulating a complete failure of a single node, FIS allows us to simulate a partial failure across multiple nodes. This provides a more nuanced and realistic failure scenario.
3. **Scale**: FIS allows us to target multiple nodes simultaneously. This allows us to test the resilience of our application at a larger scale compared to the single-node failure in the manual experiment.
4. **Precision**: We can specify exact percentages of instances to terminate, giving us fine-grained control over the experiment. This level of control wasn't possible in the manual experiment, where we were limited to terminating entire nodes.
5. **Minimal disruption**: The FIS experiment is designed to maintain service availability throughout the test, whereas the manual node failure might have caused temporary disruptions to the retail store's accessibility.

These differences allows for a more comprehensive and realistic test of our application's resilience to failures, while maintaining better control over the experiment parameters. In this experiment, FIS will terminate 66% of the instances in two node groups, simulating a significant partial failure of our cluster. Similar to previous experiments, this experiment is also repeatable

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the partial node failure:

```bash wait=30
$ export NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"COUNT(2)"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"66"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the node failure and monitor the response:

```bash timeout=300
$ aws fis start-experiment --experiment-template-id $NODE_EXP_ID --output json && timeout --preserve-status 240s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-s6kw4   1/1   Running   0     2m16s
       ui-6dfb84cf67-vwk4x   1/1   Running   0     4m54s

------us-west-2b------

------us-west-2c------
  ip-10-42-180-16.us-west-2.compute.internal:
       ui-6dfb84cf67-29xtf   1/1   Running   0     79s
       ui-6dfb84cf67-68hbw   1/1   Running   0     79s
       ui-6dfb84cf67-plv9f   1/1   Running   0     79s

```

This command triggers the node failure and monitors the pods for 4 minutes, allowing you to observe how the cluster responds to losing a significant portion of its capacity.

During the experiment, you should observe the following:

1. After about 1 minute, you'll see one or more nodes disappear from the list, representing the simulated partial node failure.
2. Over the next 2 minutes, you'll notice pods being rescheduled and redistributed to the remaining healthy nodes.
3. Shortly after you'll see the new node coming online to replace the terminated one.

Your retail url should stay operational unlike the node failure without FIS.

:::note
To verify nodes and re-balance pods, you can run:

```bash timeout=900 wait=30
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=dynamodb
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=redis
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n ui -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=service
$ sleep 90
$ kubectl rollout status -n ui deployment/ui --timeout 180s
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30
```

:::

## Verifying Retail Store Availability

Ensure that your retail store application remains operational throughout the partial node failure. Use the following command to check its availability:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

:::tip
The retail url may take 10 minutes to become operational.
:::

Despite the partial node failure, the retail store should continue to serve traffic, demonstrating the resilience of your deployment setup.

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

1. **Repeatability**: You can run this experiment multiple times to ensure consistent behavior.
2. **Automation**: FIS allows you to schedule regular resilience tests, ensuring your system maintains its fault-tolerant capabilities over time.
3. **Comprehensive testing**: You can create more complex scenarios involving multiple AWS services to test your entire application stack.
4. **Controlled chaos**: FIS provides a safe, managed environment for conducting chaos engineering experiments without risking unintended damage to your production systems.

Regular execution of such experiments helps build confidence in your system's resilience and provides valuable insights for continuous improvement of your architecture and operational procedures.
