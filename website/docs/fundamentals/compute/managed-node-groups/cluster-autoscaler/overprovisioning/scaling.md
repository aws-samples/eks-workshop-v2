---
title: "Scaling further"
sidebar_position: 50
---

In this lab exercise, we'll scale up our entire application architecture beyond what we did earlier in the Cluster Autoscaler section and observe how the responsiveness differs.

The following configuration file will be applied to scale up our application components:

```file
manifests/modules/autoscaling/compute/overprovisioning/scale/deployment.yaml
```

Let's apply these updates to our cluster:

```bash timeout=180 hook=overprovisioning-scale
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/scale
$ kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
```

As the new pods roll out, a conflict will eventually arise where the pause pods are consuming resources that the workload services could utilize. Due to our priority configuration, the pause pods will be evicted to allow the workload pods to start. This will result in some or all of the pause pods entering a `Pending` state:

```bash
$ kubectl get pod -n other -l run=pause-pods
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   0/1     Pending   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
```

This eviction process allows our workload pods to transition to `ContainerCreating` and `Running` states more quickly, demonstrating the benefits of cluster over-provisioning.

But why are these pods now pending? Shouldn't Cluster Autoscaler have provisioned additional nodes? The answer is that the Managed Node Group configured for our cluster has a maximum size of `6`, which means that we've reached the limit of the number of instances in our lab cluster.
