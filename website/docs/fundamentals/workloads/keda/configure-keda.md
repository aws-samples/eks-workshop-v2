---
title: "Configure KEDA"
sidebar_position: 10
---

When installed, KEDA creates several custom resources. One of those resources, a `ScaledObject`, enables you to map an external event source to a Deployment or StatefulSet for scaling. In this lab, we'll create a `ScaledObject` that targets the `ui` Deployment and scales this workload based on the `RequestCountPerTarget` metric in CloudWatch.

::yaml{file="manifests/modules/autoscaling/workloads/keda/scaledobject/scaledobject.yaml" paths="spec.scaleTargetRef,spec.minReplicaCount,spec.maxReplicaCount,spec.triggers"}

1. This is the resource KEDA will scale. The `name` is the name of the deployment you are targeting and your `ScaledObject` must be in the same namespace as the Deployment
2. The minimum number of replicas that KEDA will scale the deployment to
3. The maximum number of replicas that KEDA will scale the deployment to
4. The `expression` uses [CloudWatch Metrics Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-metrics-insights-querylanguage.html) syntax to select your target metric. When the `targetMetricValue` is exceeded, KEDA will scale out the workload to support the increased load. In our case, if the `RequestCountPerTarget` is greater than 100, KEDA will scale the deployment.

More details on the AWS CloudWatch scaler can be found [here](https://keda.sh/docs/scalers/aws-cloudwatch/).

First we need to gather some information about the Application Load Balancer (ALB) and Target Group that were created as part of the lab pre-requisites.

```bash
$ export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn)
$ export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
$ export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```

Now we can use those values to update the configuration of our `ScaledObject` and create the resource in the cluster.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```
