---
title: "Scaling further"
sidebar_position: 50
---

In this lab exercise, we'll scale up our entire application architecture further than we did in the CA section and see how the responsiveness differs.

```file
autoscaling/compute/overprovisioning/scale/deployment.yaml
```

Apply the updates to your cluster:

```bash timeout=180 hook=overprovisioning-scale
$ kubectl apply -k /workspace/modules/autoscaling/compute/overprovisioning/scale
$ kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
```

As the new pods roll out there will eventually be a conflict where the pause pods are consuming resources that the workload services could make use of. Because of our priority configuration the pause pod will be evicted to allow the workload pods to start. This will leave some of the pause pods in a `Pending` state:

```bash
$ kubectl get pod -n other -l run=pause-pods
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   0/1     Pending   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
```

This in turn will allow our workload pods transition to `ContainerCreating` and `Running` quicker.
