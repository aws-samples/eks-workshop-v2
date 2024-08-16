---
title: "AZ Failure Experiment Setup"
sidebar_position: 6
description: "Scale your application to two Availability Zones and prepare for an AZ failure simulation experiment."
---

This guide outlines steps to enhance the resilience of your UI service by scaling it across two Availability Zones (AZs) and preparing for an AZ failure simulation experiment.

## Scaling to Two AZs

We'll use a Kustomize patch to modify the UI deployment, adding a second AZ and adjusting the number of replicas. We'll scale to 4 replicas in the new AZ while maintaining 5 replicas in the first AZ.

First we need to make ann EKS Cluster in `us-east-2`. Run this to create a second AZ:

```bash timeout=300 wait=30
$ $SCRIPT_DIR/multi-az-get-pods.sh
$ aws configure set default.region $SECONDARY_REGION
$ prepare-environment resiliency
$ aws configure set default.region $PRIMARY_REGION
$ $SCRIPT_DIR/multi-az-get-pods.sh
```

Now we need to Kustomize our content with a patch file:

```file
manifests/modules/resiliency/high-availability/multi_az/add_us_east_2_patch.yaml
```

Apply the changes using Kustomize patch and
[Kustomization file](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/high-availability/multi_az/kustomization.yaml):

```bash
$ kubectl delete deployment ui -n ui
$ kubectl apply -k /manifests/modules/resiliency/high-availability/multi_az/
```

## Verify Retail Store Accessibility

After applying these changes, it's important to verify that your retail store is accessible:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::tip
The retail url may take 10 minutes to become operational.
:::

## Check Pod Distribution

To run the script and see the distribution of pods across availability zones, execute:

```bash
$ $SCRIPT_DIR/multi-az-get-pods.sh
```

## AZ Failure Experiment Preparation

### Overview

This experiment will simulate an Availability Zone (AZ) failure, demonstrating how resilient your application is when faced with significant infrastructure disruptions. We'll use AWS Fault Injection Simulator (FIS) and additional AWS services to test how well your system maintains functionality when an entire AZ becomes unavailable.

### Setting up a Synthetic Canary

Before starting the experiment, set up a synthetic canary for heartbeat monitoring:

1. First, create an S3 bucket for the canary artifacts:

```bash
$ BUCKET_NAME="eks-workshop-canary-artifacts-$(date +%s)"
$ aws s3 mb s3://$BUCKET_NAME --region us-west-2
```

2. Create the blueprint:

```file
manifests/modules/resiliency/scripts/eks_workshop_canary_script.js
```

Place this canary script into the bucket:

```bash
$ aws s3 cp /manifests/modules/resiliency/scripts/eks_workshop_canary_script.zip s3://$BUCKET_NAME/canary-scripts/eks_workshop_canary_script.zip
```

3. Create a synthetic canary:

```bash
$ INGRESS_URL=$(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
$ aws synthetics create-canary \
    --name eks-workshop-canary \
    --artifact-s3-location "s3://$BUCKET_NAME/canary-artifacts/" \
    --execution-role-arn $CANARY_ROLE_ARN \
    --runtime-version syn-nodejs-puppeteer-6.2 \
    --schedule Expression="rate(1 minute)" \
    --code S3Bucket=$BUCKET_NAME,S3Key=canary-scripts/eks_workshop_canary_script.zip,Handler="exports.handler" \
    --run-config "EnvironmentVariables={INGRESS_URL=http://$INGRESS_URL}" \
    --region us-west-2
$ sleep 30
$ aws synthetics start-canary --name eks-workshop-canary --region us-west-2
```

4. Create a CloudWatch alarm for the canary:

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

With these steps completed, your application is now scaled across two AZs and you've set up the necessary monitoring for the upcoming AZ failure simulation experiment.
