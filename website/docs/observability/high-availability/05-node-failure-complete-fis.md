---
title: "Simulating Complete Node Failure with FIS"
sidebar_position: 170
description: "Demonstrates the impact of a complete node failure on a Kubernetes environment using AWS Fault Injection Simulator."
---

## Overview

This experiment extends our previous partial node failure test to simulate a complete failure of all nodes in our EKS cluster. This is essentially a cluster failure. It demonstrates how AWS Fault Injection Simulator (FIS) can be used to test extreme scenarios and validate your system's resilience under catastrophic conditions.

## Experiment Details

This experiment is similar to the partial node failure as it is repeatable. Unlike the partial node failure simulation, this experiment:

1. Terminates 100% of the instances in all node groups.
2. Tests your cluster's ability to recover from a state of complete failure.
3. Allows observation of the full recovery process, from total outage to full restoration.

## Creating the Node Failure Experiment

Create a new AWS FIS experiment template to simulate the complete node failure:

```bash wait=30
$ export FULL_NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"ALL"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"100"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment and monitor the cluster's response:

```bash timeout=420
$ aws fis start-experiment --experiment-template-id $FULL_NODE_EXP_ID --output json && timeout --preserve-status 360s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-106-250.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2b------
  ip-10-42-141-133.us-west-2.compute.internal:
       ui-6dfb84cf67-n9xns   1/1   Running   0     4m8s
       ui-6dfb84cf67-slknv   1/1   Running   0     2m48s

------us-west-2c------
  ip-10-42-179-59.us-west-2.compute.internal:
       ui-6dfb84cf67-5xht5   1/1   Running   0     4m52s
       ui-6dfb84cf67-b6xbf   1/1   Running   0     4m10s
       ui-6dfb84cf67-fpg8j   1/1   Running   0     4m52s
```

This command will show the pods distribution over 6 minutes while we observe the experiment. We should see:

1. Shortly after the experiment is initiated, all nodes and pods disappear.
2. After about 2 minutes, First node and some pods will come back online.
3. Around 4 minutes, a second node appears and more pods start up.
4. At 6 minutes, continued recovery as the last node come online.

Due to the severity of the experiment, the retail store url will not stay operational during testing. The url should come back up after the final node is operational. If the node is not operational after this test, run `~/$SCRIPT_DIR/verify-clsuter.sh` to wait for the final node to change state to running before proceeding.

:::note
To verify nodes and pods redistribution, you can run:

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

Check the retail store application's recovery:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
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
