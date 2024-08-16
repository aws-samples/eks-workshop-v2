---
title: "Simulating AZ Failure"
sidebar_position: 7
description: "This experiment simulates an Availability Zone failure to test the resilience of your Kubernetes environment hosted on AWS EKS."
---

# Simulating AZ Failure

## Overview

This experiment simulates an Availability Zone (AZ) failure, demonstrating the resilience of your application when faced with significant infrastructure disruptions. By leveraging AWS Fault Injection Simulator (FIS) and additional AWS services, we'll test how well your system maintains functionality when an entire AZ becomes unavailable.

### Setting up the Experiment

Retrieve the Auto Scaling Group (ASG) name associated with your EKS cluster:

```bash
$ ASG_NAME_BOTH=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eks-workshop']]".AutoScalingGroupName --output text)
$ ASG_NAME=$(echo $ASG_NAME_BOTH | awk '{print $1}')
```

Create the FIS experiment template to simulate the AZ failure:

```bash
$ ZONE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"publicdocument-azfailure","targets":{},"actions":{"azfailure":{"actionId":"aws:ssm:start-automation-execution","parameters":{"documentArn":"arn:aws:ssm:us-west-2::document/AWSResilienceHub-SimulateAzOutageInAsgTest_2020-07-23","documentParameters":"{\"AutoScalingGroupName\":\"'$ASG_NAME'\",\"CanaryAlarmName\":\"eks-workshop-canary-alarm\",\"AutomationAssumeRole\":\"'$FIS_ROLE_ARN'\",\"IsRollback\":\"false\",\"TestDurationInMinutes\":\"2\"}","maxDuration":"PT6M"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix":"'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the AZ failure:

```bash
$ aws fis start-experiment --experiment-template-id $ZONE_EXP_ID --output json && SECONDS=0; while [ $SECONDS -lt 450 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command starts the experiment and monitors the distribution and status of pods across different nodes and AZs for 7.5 minutes to understand the immediate impact of the simulated AZ failure.

During the experiment, you should observe the following sequence of events:

- input here

:::note
To verify clusters and rebalance pods, you can run:

```bash
$ $SCRIPT_DIR/verify-cluster.sh
```

:::

## Post-Experiment Verification

After the experiment, verify that your application remains operational despite the simulated AZ failure:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

This step confirms the effectiveness of your Kubernetes cluster's high availability configuration and its ability to maintain service continuity during significant infrastructure disruptions.

## Conclusion

The AZ failure simulation represents a critical test of your EKS cluster's resilience and your application's high availability design. Through this experiment, you've gained valuable insights into:

1. The effectiveness of your multi-AZ deployment strategy
2. Kubernetes' ability to reschedule pods across remaining healthy AZs
3. The impact of an AZ failure on your application's performance and availability
4. The efficiency of your monitoring and alerting systems in detecting and responding to major infrastructure issues

Key takeaways from this experiment include:

- The importance of distributing your workload across multiple AZs
- The value of proper resource allocation and pod anti-affinity rules
- The need for robust monitoring and alerting systems that can quickly detect AZ-level issues
- The effectiveness of your disaster recovery and business continuity plans

By regularly conducting such experiments, you can:

- Identify potential weaknesses in your infrastructure and application architecture
- Refine your incident response procedures
- Build confidence in your system's ability to withstand major failures
- Continuously improve your application's resilience and reliability

Remember, true resilience comes not just from surviving such failures, but from maintaining performance and user experience even in the face of significant infrastructure disruptions. Use the insights gained from this experiment to further enhance your application's fault tolerance and ensure seamless operations across all scenarios.
