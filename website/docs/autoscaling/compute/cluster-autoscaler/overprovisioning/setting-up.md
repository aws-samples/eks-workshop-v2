---
title: "Setting up Over-Provisioning"
sidebar_position: 35
---

It's considered a best practice to create appropriate `PriorityClass` for your applications. Now, let's create a global default priority class using the field `globalDefault:true`. This default `PriorityClass` will be assigned pods/deployments that don’t specify a `PriorityClassName`.

```file
autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml
```

We'll also create `PriorityClass` that will be assigned to pause pods used for over-provisioning with priority value `-1`.

```file
autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml
```

Pause pods make sure there are enough nodes that are available based on how much over provisioning is needed for your environment. Keep in mind the `—max-size` parameter in ASG (of EKS node group). Cluster Autoscaler won’t increase number of nodes beyond this maximum specified in the ASG

```file
autoscaling/compute/overprovisioning/setup/deployment-pause.yaml
```

In this case we're going to schedule a single pause pod requesting `7Gi` of memory, which means it will consume basically entire `m5.large` instance. This will result in us always having a "spare" worker node available.

Apply the updates to your cluster:

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k /workspace/modules/autoscaling/compute/overprovisioning/setup
```
