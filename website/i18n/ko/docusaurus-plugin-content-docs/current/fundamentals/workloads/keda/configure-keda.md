---
title: "KEDA 구성"
sidebar_position: 10
tmdTranslationSourceHash: '093255d067fa7fc75b91cdf4a8f48834'
---

KEDA가 설치되면 여러 개의 사용자 정의 리소스가 생성됩니다. 이러한 리소스 중 하나인 `ScaledObject`를 사용하면 외부 이벤트 소스를 Deployment 또는 StatefulSet에 매핑하여 스케일링할 수 있습니다. 이 실습에서는 `ui` Deployment를 타겟으로 하는 `ScaledObject`를 생성하고 CloudWatch의 `RequestCountPerTarget` 메트릭을 기반으로 이 워크로드를 스케일링합니다.

::yaml{file="manifests/modules/autoscaling/workloads/keda/scaledobject/scaledobject.yaml" paths="spec.scaleTargetRef,spec.minReplicaCount,spec.maxReplicaCount,spec.triggers"}

1. 이것은 KEDA가 스케일링할 리소스입니다. `name`은 타겟으로 하는 Deployment의 이름이며 `ScaledObject`는 Deployment와 동일한 네임스페이스에 있어야 합니다
2. KEDA가 Deployment를 스케일링할 최소 레플리카 수입니다
3. KEDA가 Deployment를 스케일링할 최대 레플리카 수입니다
4. `expression`은 [CloudWatch Metrics Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-metrics-insights-querylanguage.html) 구문을 사용하여 타겟 메트릭을 선택합니다. `targetMetricValue`를 초과하면 KEDA는 증가된 부하를 지원하기 위해 워크로드를 스케일 아웃합니다. 우리의 경우 `RequestCountPerTarget`이 100보다 크면 KEDA가 Deployment를 스케일링합니다.

AWS CloudWatch 스케일러에 대한 자세한 내용은 [여기](https://keda.sh/docs/scalers/aws-cloudwatch/)에서 확인할 수 있습니다.

먼저 실습 사전 준비 단계에서 생성된 Application Load Balancer(ALB)와 Target Group에 대한 정보를 수집해야 합니다.

```bash
$ export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn)
$ export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
$ export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```

이제 이러한 값을 사용하여 `ScaledObject`의 구성을 업데이트하고 클러스터에 리소스를 생성할 수 있습니다.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```

