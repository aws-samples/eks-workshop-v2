---
title: "AZ Failure Experiment Setup"
sidebar_position: 190
description: "Scale your application to two instances and prepare for an AZ failure simulation experiment."
---

### Scaling Instances

To see the full impact of an Availability Zone (AZ) failure, let's first scale up to two instances per AZ as well as increase the number of pods up to 9:

```bash timeout=120 wait=30
$ export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eks-workshop']].AutoScalingGroupName" --output text)
$ aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $ASG_NAME \
    --desired-capacity 6 \
    --min-size 6 \
    --max-size 6
$ sleep 60
$ kubectl scale deployment ui --replicas=9 -n ui
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30

------us-west-2a------
  ip-10-42-100-4.us-west-2.compute.internal:
       ui-6dfb84cf67-xbbj4   0/1   ContainerCreating   0     1s
  ip-10-42-106-250.us-west-2.compute.internal:
       ui-6dfb84cf67-4fjhh   1/1   Running   0     5m20s
       ui-6dfb84cf67-gkrtn   1/1   Running   0     5m19s

------us-west-2b------
  ip-10-42-139-198.us-west-2.compute.internal:
       ui-6dfb84cf67-7rfkf   0/1   ContainerCreating   0     4s
  ip-10-42-141-133.us-west-2.compute.internal:
       ui-6dfb84cf67-7qnkz   1/1   Running   0     5m23s
       ui-6dfb84cf67-n58b9   1/1   Running   0     5m23s

------us-west-2c------
  ip-10-42-175-140.us-west-2.compute.internal:
       ui-6dfb84cf67-8xfk8   0/1   ContainerCreating   0     8s
       ui-6dfb84cf67-s55nb   0/1   ContainerCreating   0     8s
  ip-10-42-179-59.us-west-2.compute.internal:
       ui-6dfb84cf67-lvdc2   1/1   Running   0     5m26s
```

### Setting up a Synthetic Canary

Before starting the experiment, set up a synthetic canary for heartbeat monitoring:

1. First, create an S3 bucket for the canary artifacts:

   ```bash wait=30
   $ export BUCKET_NAME="eks-workshop-canary-artifacts-$(date +%s)"
   $ aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

   make_bucket: eks-workshop-canary-artifacts-1724131402
   ```

2. Create the blueprint:

   ```file
   manifests/modules/observability/resiliency/scripts/create-blueprint.sh
   ```

   Place this canary blueprint into the bucket:

   ```bash wait=30
   $ ~/$SCRIPT_DIR/create-blueprint.sh

   upload: ./canary.zip to s3://eks-workshop-canary-artifacts-1724131402/canary-scripts/canary.zip
   Canary script has been zipped and uploaded to s3://eks-workshop-canary-artifacts-1724131402/canary-scripts/canary.zip
   The script is configured to check the URL: http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
   ```

3. Create a synthetic canary with a Cloudwatch alarm:

   ```bash wait=60
   $ aws synthetics create-canary \
   --name eks-workshop-canary \
   --artifact-s3-location "s3://$BUCKET_NAME/canary-artifacts/" \
   --execution-role-arn $CANARY_ROLE_ARN \
   --runtime-version syn-nodejs-puppeteer-9.0 \
   --schedule "Expression=rate(1 minute)" \
   --code "Handler=canary.handler,S3Bucket=$BUCKET_NAME,S3Key=canary-scripts/canary.zip" \
   --region $AWS_REGION
   $ sleep 40
   $ aws synthetics describe-canaries --name eks-workshop-canary --region $AWS_REGION
   $ aws synthetics start-canary --name eks-workshop-canary --region $AWS_REGION
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
   --region $AWS_REGION
   ```

This sets up a canary that checks the health of your application every minute and a CloudWatch alarm that triggers if the success percentage falls below 95%.

With these steps completed, your application is now scaled across to two instances in AZs and you've set up the necessary monitoring for the upcoming AZ failure simulation experiment.
