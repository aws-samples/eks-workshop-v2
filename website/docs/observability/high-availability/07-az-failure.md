---
title: "Simulating AZ Failure"
sidebar_position: 210
description: "This experiment simulates an Availability Zone failure to test the resilience of your Kubernetes environment hosted on AWS EKS."
---

## Overview

This repeatable experiment simulates an Availability Zone (AZ) failure, demonstrating the resilience of your application when faced with significant infrastructure disruptions. By leveraging AWS Fault Injection Simulator (FIS) and additional AWS services, we'll test how well your system maintains functionality when an entire AZ becomes unavailable.

### Setting up the Experiment

Retrieve the Auto Scaling Group (ASG) name associated with your EKS cluster and create the FIS experiment template to simulate the AZ failure:

```bash wait=30
$ export ZONE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"publicdocument-azfailure","targets":{},"actions":{"azfailure":{"actionId":"aws:ssm:start-automation-execution","parameters":{"documentArn":"arn:aws:ssm:us-west-2::document/AWSResilienceHub-SimulateAzOutageInAsgTest_2020-07-23","documentParameters":"{\"AutoScalingGroupName\":\"'$ASG_NAME'\",\"CanaryAlarmName\":\"eks-workshop-canary-alarm\",\"AutomationAssumeRole\":\"'$FIS_ROLE_ARN'\",\"IsRollback\":\"false\",\"TestDurationInMinutes\":\"2\"}","maxDuration":"PT6M"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix":"'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the AZ failure:

```bash timeout=540
$ aws fis start-experiment --experiment-template-id $ZONE_EXP_ID --output json && timeout --preserve-status 480s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-100-4.us-west-2.compute.internal:
       ui-6dfb84cf67-h57sp   1/1   Running   0     12m
       ui-6dfb84cf67-h87h8   1/1   Running   0     12m
  ip-10-42-111-144.us-west-2.compute.internal:
       ui-6dfb84cf67-4xvmc   1/1   Running   0     11m
       ui-6dfb84cf67-crl2s   1/1   Running   0     6m23s

------us-west-2b------
  ip-10-42-141-243.us-west-2.compute.internal:
       No resources found in ui namespace.
  ip-10-42-150-255.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2c------
  ip-10-42-164-250.us-west-2.compute.internal:
       ui-6dfb84cf67-fl4hk   1/1   Running   0     11m
       ui-6dfb84cf67-mptkw   1/1   Running   0     11m
       ui-6dfb84cf67-zxnts   1/1   Running   0     6m27s
  ip-10-42-178-108.us-west-2.compute.internal:
       ui-6dfb84cf67-8vmcz   1/1   Running   0     6m28s
       ui-6dfb84cf67-wknc5   1/1   Running   0     12m
```

This command starts the experiment and monitors the distribution and status of pods across different nodes and AZs for 8 minutes to understand the immediate impact of the simulated AZ failure.

During the experiment, you should observe the following sequence of events:

1. After about 3 minutes, an AZ zone will fail.
2. Looking at the [Synthetic Canary](<https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#alarmsV2:alarm/eks-workshop-canary-alarm?~(alarmStateFilter~'ALARM)>) you will see change state to `In Alarm`
3. Around 4 minutes after the experiment started, you will see pods reappearing in the other AZs
4. After the experiment is complete, after about 7 minutes, it marks the AZ as healthy, and replacement EC2 instances will be launched as a result of an EC2 autoscaling action, bringing the number of instances in each AZ to 2 again.

During this time, the retail url will stay available showing how resilient EKS is to AZ failures.

:::note
To verify nodes and pods redistribution, you can run:

```bash timeout=900 wait=30
$ EXPECTED_NODES=6 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
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

## Post-Experiment Verification

After the experiment, verify that your application remains operational despite the simulated AZ failure:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
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
