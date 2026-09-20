---
title: "Pod Readiness Gate"
sidebar_position: 40
---

The AWS Load Balancer controller supports [Pod readiness gate](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/pod_readiness_gate/) to indicate that pod is registered to the ALB/NLB and healthy to receive traffic. The controller automatically injects the necessary readiness gate configuration to the pod spec via mutating webhook during pod creation.

:::info
Note that This only works with `target-type: ip`, since when using `target-type: instance`, it's the node used as backend, the ALB itself is not aware of pod/podReadiness in such case.
:::

The current ui service is not using readiness gate (last column is set to `<none>`).
These informations are only visible on wide output:

```bash
$ kubectl -n ui get pods --output wide
NAME                  READY   STATUS    RESTARTS   AGE     IP             NODE                                          NOMINATED NODE   READINESS GATES
ui-5989474687-swm27   1/1     Running   0          2m24s   10.42.181.33   ip-10-42-176-252.us-west-2.compute.internal   <none>           <none>
```

We will observe the current situation by doing a rollout the deployment.
You'll notice that the old pod id terminated immediately after being `Ready`.
If you'll be quick, you can observe the healcheck status of the new pod in the ALB target group:

```bash
$ kubectl -n ui get pods --output wide 
NAME                  READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dbf768d69-vx2cz   1/1     Running   0          20s   10.42.142.144   ip-10-42-137-174.us-west-2.compute.internal   <none>           <none>
$ kubectl -n ui rollout restart deployment ui 
deployment.apps/ui restarted
$ kubectl -n ui get pods --output wide 
NAME                  READY   STATUS        RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-5d5c6b587d-x5pgz   1/1     Running       0          2s    10.42.181.37    ip-10-42-176-252.us-west-2.compute.internal   <none>           <none>
ui-6dbf768d69-vx2cz   1/1     Terminating   0          30s   10.42.142.144   ip-10-42-137-174.us-west-2.compute.internal   <none>           <none>
$ kubectl -n ui get pods --output wide 
NAME                  READY   STATUS    RESTARTS   AGE   IP             NODE                                          NOMINATED NODE   READINESS GATES
ui-5d5c6b587d-x5pgz   1/1     Running   0          6s    10.42.181.37   ip-10-42-176-252.us-west-2.compute.internal   <none>           <none>
TG_ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName, 'k8s-ui-ui')].TargetGroupArn" --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[].TargetHealth
```

output as:

```json
{
    "State": "initial",
    "Reason": "Elb.RegistrationInProgress",
    "Description": "Target registration is in progress"
}
```

and after some seconds:

```json
{
    "State": "healthy"
}
```

During this delay our ui application will be unreachable (502 errors).

In order to avoid this situation, the AWS Load Balancer controller can set the readiness condition on the pods that constitute your ingress or service backend. The condition status on a pod will be set to `True` only when the corresponding target in the ALB/NLB target group shows a health state of `Healthy`. This prevents the rolling update of a deployment from terminating old pods until the newly created pods are `Healthy` in the ALB/NLB target group and ready to take traffic.

For readiness gate configuration to be injected to the pod spec, you need to apply the label `elbv2.k8s.aws/pod-readiness-gate-inject: enabled` to the pod namespace:

```bash
$ kubectl label namespace ui elbv2.k8s.aws/pod-readiness-gate-inject=enabled
namespace/ui labeled
```

We need to rollout the deployment to enable it:

```bash
$ kubectl -n ui rollout restart deployment ui 
```

You can observe that the `Ready` status is `False` as the target health:
```bash
$ kubectl describe pod -n ui -l app.kubernetes.io/name=ui | grep --after-context=10 "Conditions:"
Conditions:
  Type                                               Status
  target-health.elbv2.k8s.aws/k8s-ui-ui-b21a807597   False 
  PodReadyToStartContainers                          True 
  Initialized                                        True 
  Ready                                              False 
  ContainersReady                                    True 
  PodScheduled                                       True 
```

After the target healthcheck is Ready:

```bash
$ kubectl describe pod -n ui -l app.kubernetes.io/name=ui | grep --after-context=10 "Conditions:"
Conditions:
  Type                                               Status
  target-health.elbv2.k8s.aws/k8s-ui-ui-b21a807597   True 
  PodReadyToStartContainers                          True 
  Initialized                                        True 
  Ready                                              True 
  ContainersReady                                    True 
  PodScheduled                                       True 
```

Now the pod has readiness gate enabled, we can observe that the old pod isn't terminated unless the readiness success on the new pod if we do another rollout deployment:

```bash
$ kubectl -n ui rollout restart deployment ui
deployment.apps/ui restarted
$ kubectl -n ui get pods --output wide 
NAME                 READY   STATUS    RESTARTS   AGE    IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-886bb64b8-cxmsx   1/1     Running   0          103s   10.42.158.114   ip-10-42-137-174.us-west-2.compute.internal   <none>           1/1
[...]
$ kubectl -n ui get pods --output wide 
NAME                  READY   STATUS    RESTARTS   AGE    IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-886bb64b8-cxmsx    1/1     Running   0          112s   10.42.158.114   ip-10-42-137-174.us-west-2.compute.internal   <none>           1/1
ui-6fd4c6cc49-f8tqm   1/1     Running   0          3s     10.42.181.33    ip-10-42-176-252.us-west-2.compute.internal   <none>           0/1
[...]
$ kubectl -n ui get pods --output wide 
NAME                  READY   STATUS    RESTARTS   AGE   IP             NODE                                          NOMINATED NODE   READINESS GATES
ui-6fd4c6cc49-f8tqm   1/1     Running   0          66s   10.42.181.33   ip-10-42-176-252.us-west-2.compute.internal   <none>           1/1
```

This let the ui still reachable during the rollout.
