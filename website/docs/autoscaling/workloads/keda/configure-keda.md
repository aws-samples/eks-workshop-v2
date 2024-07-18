---
title: "Configure KEDA"
sidebar_position: 15
---

Now let's

```file
manifests/modules/autoscaling/workloads/keda/scaledobject/scaledobject.yaml
```

First we need to gather some information about the load balancer and target group that were created.

```bash
$ export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn)
$ export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
$ export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```

Now

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```