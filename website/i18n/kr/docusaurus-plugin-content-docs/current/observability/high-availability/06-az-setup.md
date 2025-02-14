---
title: "AZ 장애 실험 설정"
sidebar_position: 190
description: "애플리케이션을 두 개의 인스턴스로 확장하고 AZ 장애 시뮬레이션 실험을 준비합니다."
---

### 인스턴스 확장

가용 영역(AZ) 장애의 전체적인 영향을 확인하기 위해, 먼저 AZ당 두 개의 인스턴스로 확장하고 파드 수를 9개까지 늘려보겠습니다:

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

### 합성 카나리 설정

실험을 시작하기 전에, 하트비트 모니터링을 위한 합성 카나리를 설정하세요:

1. 먼저, 카나리 아티팩트를 위한 S3 버킷을 생성합니다:

   ```bash wait=30
   $ export BUCKET_NAME="eks-workshop-canary-artifacts-$(date +%s)"
   $ aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

   make_bucket: eks-workshop-canary-artifacts-1724131402
   ```

2. 블루프린트를 생성합니다:

   ```file
   manifests/modules/observability/resiliency/scripts/create-blueprint.sh
   ```

   이 카나리 블루프린트를 버킷에 넣습니다:

   ```bash wait=30
   $ ~/$SCRIPT_DIR/create-blueprint.sh

   upload: ./canary.zip to s3://eks-workshop-canary-artifacts-1724131402/canary-scripts/canary.zip
   Canary script has been zipped and uploaded to s3://eks-workshop-canary-artifacts-1724131402/canary-scripts/canary.zip
   The script is configured to check the URL: http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
   ```

3. Cloudwatch 경보가 포함된 합성 카나리를 생성합니다:

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

이렇게 하면 매 분마다 애플리케이션의 상태를 확인하는 카나리와 성공률이 95% 미만으로 떨어질 경우 트리거되는 CloudWatch 경보가 설정됩니다.

이러한 단계들이 완료되면, 이제 애플리케이션이 AZ의 두 인스턴스로 확장되었고 앞으로 있을 AZ 장애 시뮬레이션 실험을 위한 필요한 모니터링이 설정된 것입니다.