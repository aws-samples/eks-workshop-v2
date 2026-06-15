---
title: "KEDAの設定"
sidebar_position: 10
tmdTranslationSourceHash: 'c96cb78211f58bb444430338982960a3'
---

KEDAをインストールすると、いくつかのカスタムリソースが作成されます。これらのリソースの1つである`ScaledObject`を使用すると、外部イベントソースをDeploymentまたはStatefulSetにマッピングしてスケーリングすることができます。このラボでは、`ui` Deploymentをターゲットとし、CloudWatchの`RequestCountPerTarget`メトリクスに基づいてこのワークロードをスケーリングする`ScaledObject`を作成します。

::yaml{file="manifests/modules/autoscaling/workloads/keda/scaledobject/scaledobject.yaml" paths="spec.scaleTargetRef,spec.minReplicaCount,spec.maxReplicaCount,spec.triggers"}

1. これはKEDAがスケーリングするリソースです。`name`はターゲットとするDeploymentの名前で、`ScaledObject`はDeploymentと同じNamespaceに存在する必要があります
2. KEDAがDeploymentをスケーリングする際の最小レプリカ数
3. KEDAがDeploymentをスケーリングする際の最大レプリカ数
4. `expression`は[CloudWatch Metrics Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-metrics-insights-querylanguage.html)構文を使用してターゲットメトリクスを選択します。`targetMetricValue`を超えると、KEDAはワークロードをスケールアウトして増加した負荷に対応します。この例では、`RequestCountPerTarget`が100を超えると、KEDAはDeploymentをスケーリングします。

AWS CloudWatch scalerの詳細については、[こちら](https://keda.sh/docs/scalers/aws-cloudwatch/)をご覧ください。

まず、ラボの前提条件の一部として作成されたApplication Load Balancer (ALB)とTarget Groupに関する情報を収集する必要があります。

```bash
$ export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto-`) == `true`]' | jq -r .[0].LoadBalancerArn)
$ export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto-`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
$ export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```

これらの値を使用して、`ScaledObject`の設定を更新し、クラスターにリソースを作成できます。

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```

