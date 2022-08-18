---
title: "Scale a workload"
sidebar_position: 40
---

Now lets scale a workload to see how the priority is used. We'll scale the `ui` service up to 5 replicas so that it consumes more resources:

```file
autoscaling/compute/overprovisioning/scale/deployment-ui.yaml
```

Apply the updates to your cluster:

```bash timeout=180 hook=overprovisioning-scale
kubectl apply -k /workspace/modules/autoscaling/compute/overprovisioning/scale
```

As the new `ui` pods rollout, there will eventually be a conflict where the pause pods are consuming resources that the `ui` service could make use of. Because of our priority configuration, one or more pause pods will be evicted to allow the `ui` pods to start. This will leave some of the pause pods in a `Pending` state:

```bash
kubectl get pod -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   1/1     Running   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
pause-pods-5556d545f7-qxhp6   1/1     Running   0          16m
```

Our `ui` service on the other hand will have all of its pods running:

```bash
kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-79ccc7d5d8-8hz2h   1/1     Running   0          68m
ui-79ccc7d5d8-dpk64   1/1     Running   0          2m59s
ui-79ccc7d5d8-hp9l8   1/1     Running   0          2m59s
ui-79ccc7d5d8-n88rk   1/1     Running   0          2m59s
ui-79ccc7d5d8-xplhg   1/1     Running   0          2m59s
```