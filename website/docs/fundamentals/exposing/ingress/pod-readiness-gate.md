---
title: "Pod readiness gate"
sidebar_position: 40
---

When a Deployment rolls out, Kubernetes terminates an old Pod as soon as its replacement reports `Ready`. With an ALB in front of the Pods, `Ready` only means the container passed its own probes: the new Pod still has to be registered in the target group and pass the ALB health checks. With a small number of replicas, there can be a moment where every target is either still `initial` or already `draining`, and the ALB returns errors.

The AWS Load Balancer Controller solves this with [Pod readiness gates](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/pod_readiness_gate/). The controller adds a readiness gate to each Pod behind a target group, and only sets it to `True` once the matching target is `healthy` in the ALB. A rolling update then waits for the new Pod to be healthy in the ALB before it terminates an old one.

:::info
Readiness gates only work with `target-type: ip`, which is what the Ingress in this lab uses. With `target-type: instance` the targets are nodes, so the ALB has no view of individual Pods.
:::

The `READINESS GATES` column of the wide output shows that the `ui` Pods currently have none:

```bash
$ kubectl -n ui get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP             NODE                                          NOMINATED NODE   READINESS GATES
ui-5989474687-swm27   1/1     Running   0          2m24s   10.42.181.33   ip-10-42-176-252.us-west-2.compute.internal   <none>           <none>
```

Restart the Deployment to see what a rollout looks like without a readiness gate:

```bash timeout=180
$ kubectl -n ui rollout restart deployment ui
deployment.apps/ui restarted
$ kubectl -n ui rollout status deployment ui --timeout=120s
deployment "ui" successfully rolled out
```

The rollout completes as soon as the new Pod is `Ready`, and the old Pod is already terminating. Check the target group of the `ui` load balancer straight away:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --query 'TargetHealthDescriptions[].TargetHealth'
[
    {
        "State": "initial",
        "Reason": "Elb.RegistrationInProgress",
        "Description": "Target registration is in progress"
    },
    {
        "State": "draining",
        "Reason": "Target.DeregistrationInProgress",
        "Description": "Target deregistration is in progress"
    }
]
```

Depending on timing you may only see the new target, or it may already be `healthy`. While no target is `healthy`, requests to the application fail with HTTP 502 or 503 errors.

Readiness gate injection is enabled per namespace. Label the `ui` namespace so the controller's webhook adds the readiness gate to new Pods:

```bash
$ kubectl label namespace ui elbv2.k8s.aws/pod-readiness-gate-inject=enabled
namespace/ui labeled
```

The gate is only added when a Pod is created, so restart the Deployment again. This time the rollout waits for the new Pod to become healthy in the ALB:

```bash timeout=300 hook=readiness-gate hookTimeout=300
$ kubectl -n ui rollout restart deployment ui
deployment.apps/ui restarted
$ kubectl -n ui rollout status deployment ui --timeout=240s
deployment "ui" successfully rolled out
```

While the rollout is in progress, the new Pod shows `0/1` readiness gates and the old Pod keeps serving traffic. Once the target is `healthy` the gate changes to `1/1`, and only then is the old Pod terminated:

```bash test=false
$ kubectl -n ui get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE    IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-886bb64b8-cxmsx    1/1     Running   0          112s   10.42.158.114   ip-10-42-137-174.us-west-2.compute.internal   <none>           1/1
ui-6fd4c6cc49-f8tqm   1/1     Running   0          3s     10.42.181.33    ip-10-42-176-252.us-west-2.compute.internal   <none>           0/1
```

The readiness gate is a Pod condition whose type starts with `target-health.elbv2.k8s.aws/`, followed by the name of the target group binding:

```bash
$ kubectl -n ui get pods -l app.kubernetes.io/name=ui \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.conditions[*]}{"  "}{.type}={.status}{"\n"}{end}{end}'
ui-6fd4c6cc49-f8tqm
  target-health.elbv2.k8s.aws/k8s-ui-ui-b21a807597=True
  PodReadyToStartContainers=True
  Initialized=True
  Ready=True
  ContainersReady=True
  PodScheduled=True
```

The Pod is only `Ready` once this condition is `True`, so the `ui` application stays reachable for the whole rollout.
