---
title: "KEDAの設定"
sidebar_position: 10
tmdTranslationSourceHash: "093255d067fa7fc75b91cdf4a8f48834"
---

KEDAがインストールされると、複数のカスタムリソースが作成されます。これらのリソースの1つである`ScaledObject`を使用すると、外部イベントソースをDeploymentまたはStatefulSetにマッピングしてスケーリングできます。このラボでは、`ui` Deploymentをターゲットとする`ScaledObject`を作成し、CloudWatchの`RequestCountPerTarget`メトリクスに基づいてこのワークロードをスケールします。

::yaml{file="manifests/modules/autoscaling/workloads/keda/scaledobject/scaledobject.yaml" paths="spec.scaleTargetRef,spec.minReplicaCount,spec.maxReplicaCount,spec.triggers"}

1. これはKEDAがスケールするリソースです。`name`はターゲットとするdeploymentの名前であり、`ScaledObject`はDeploymentと同じnamespaceに存在する必要があります
2. KEDAがdeploymentをスケールする最小レプリカ数
3. KEDAがdeploymentをスケールする最大レプリカ数
4. `expression`は[CloudWatch Metrics Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-metrics-insights-querylanguage.html)構文を使用してターゲットメトリクスを選択します。`targetMetricValue`を超えると、KEDAは負荷の増加に対応するためにワークロードをスケールアウトします。この場合、`RequestCountPerTarget`が100を超えると、KEDAはdeploymentをスケールします。

AWS CloudWatchスケーラーの詳細については[こちら](https://keda.sh/docs/scalers/aws-cloudwatch/)をご覧ください。

まず、ラボの前提条件として作成されたApplication Load Balancer（ALB）とTarget Groupに関する情報を収集する必要があります。

```bash
$ export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn)
$ export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
$ export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```

これらの値を使用して、`ScaledObject`の設定を更新し、クラスターにリソースを作成できます。

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```
