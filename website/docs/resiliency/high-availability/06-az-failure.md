---
title: "Simulating AZ Failure"
sidebar_position: 6
description: "This experiment simulates an Availability Zone failure to test the resilience of your Kubernetes environment hosted on AWS EKS."
---

# Simulating AZ Failure

TODO:

- Fix canary
- Check AZ failure still works
- add specific cloudwatch iam role
- add conclustion

## Overview

This experiment simulates an Availability Zone (AZ) failure, demonstrating how robust your application is when faced with significant disruptions. It leverages AWS Fault Injection Simulator (FIS) and additional AWS services to test the resilience of the system under the stress of an AZ going offline.

## Preparation

### Setting up a Synthetic Canary

Before starting the experiment, set up a synthetic canary for heartbeat monitoring:

1. First, create an S3 bucket for the canary artifacts:

```bash
$ BUCKET_NAME="eks-workshop-canary-artifacts-$(date +%s)"
$ aws s3 mb s3://$BUCKET_NAME --region us-west-2
```

2. Create the canary:

Set up the blueprint:

```bash
$ INGRESS_URL=$(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
$ cat <<EOF > canary_script.js
var synthetics = require('Synthetics');
var log = require('SyntheticsLogger');

const pageLoadBlueprint = async function () {
    const PAGE_LOAD_TIMEOUT = 30;
    const URL = 'http://${INGRESS_URL}';
    let page = await synthetics.getPage();
    await synthetics.executeStep('Navigate to ' + URL, async function () {
        await page.goto(URL, {waitUntil: 'domcontentloaded', timeout: PAGE_LOAD_TIMEOUT * 1000});
    });
    await synthetics.executeStep('Page loaded successfully', async function () {
        log.info('Page loaded successfully');
    });
};

exports.handler = async () => {
    return await pageLoadBlueprint();
};
EOF
$ aws s3 cp canary_script.js s3://$BUCKET_NAME/canary-script/canary_script.js
```

Create a synthetic canary:

```bash
$ INGRESS_URL=$(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
$ aws synthetics create-canary \
    --name eks-workshop-canary \
    --artifact-s3-location "s3://$BUCKET_NAME/canary-artifacts/" \
    --execution-role-arn $FIS_ROLE_ARN \
    --runtime-version syn-nodejs-puppeteer-9.0 \
    --schedule Expression="rate(1 minute)" \
    --code S3Bucket=$BUCKET_NAME,S3Key=canary-script/canary_script.js,Handler="canary_script.handler" \
    --region us-west-2
$ sleep 30
$ aws synthetics start-canary --name eks-workshop-canary --region us-west-2
```

3. Create a CloudWatch alarm for the canary:

```bash
$ aws cloudwatch put-metric-alarm \
    --alarm-name "eks-workshop-canary-alarm" \
    --metric-name SuccessPercent \
    --namespace CloudWatchSynthetics \
    --statistic Average \
    --period 60 \
    --threshold 95 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=CanaryName,Value=eks-workshop-canary \
    --evaluation-periods 1 \
    --alarm-description "Alarm when Canary success rate drops below 95%" \
    --unit Percent \
    --region us-west-2
```

This sets up a canary that checks the health of your application every minute and a CloudWatch alarm that triggers if the success percentage falls below 95%.

### Setting up the Experiment

Retrieve the Auto Scaling Group (ASG) name associated with your EKS cluster:

```bash
$ ASG_NAME_BOTH=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eks-workshop']]".AutoScalingGroupName --output text)
$ ASG_NAME=$(echo $ASG_NAME_BOTH | awk '{print $1}')
```

Create the FIS experiment template to simulate the AZ failure:

```bash
$ ZONE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"publicdocument-azfailure","targets":{},"actions":{"azfailure":{"actionId":"aws:ssm:start-automation-execution","parameters":{"documentArn":"arn:aws:ssm:us-west-2::document/AWSResilienceHub-SimulateAzOutageInAsgTest_2020-07-23","documentParameters":"{\"AutoScalingGroupName\":\"'$ASG_NAME'\",\"CanaryAlarmName\":\"eks-workshop-canary-alarm\",\"AutomationAssumeRole\":\"arn:aws:iam::'$AWS_ACCOUNT_ID':role/WSParticipantRole\",\"IsRollback\":\"false\",\"TestDurationInMinutes\":\"2\"}","maxDuration":"PT6M"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix":"'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## Running the Experiment

Execute the FIS experiment to simulate the AZ failure:

```bash
aws fis start-experiment --experiment-template-id $ZONE_EXP_ID --output json && \
timeout 450 watch -n 1 --color $SCRIPT_DIR/get-pods-by-az.sh
```

This command starts the experiment and monitors the distribution and status of pods across different nodes and AZs to understand the immediate impact of the simulated AZ failure.

## Post-Experiment Verification

Ensure that your application remains operational despite the simulated AZ failure, confirming the effectiveness of Kubernetes high availability:

```bash
wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

## Conclusion

This experiment demonstrates the resilience of your EKS cluster in the face of an Availability Zone failure. By monitoring the canary and observing the redistribution of pods, you can assess how well your application maintains availability during significant infrastructure disruptions.
