---
title: "Setting up Over-Provisioning"
sidebar_position: 35
---

It is best practice to create appropriate `PriorityClass` for your applications. We'll create a global default priority class using the field `globalDefault:true`. This default `PriorityClass` will be assigned pods/deployments that don’t specify a `PriorityClassName`.

```file
autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml
```

Next create `PriorityClass` that will be assigned to Pause Container pods used for over provisioning with priority value `-1`.

```file
autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml
```

Pause containers make sure there are enough nodes that are available based on how much over provisioning is needed for your environment. Keep in mind the `—max-size` parameter in ASG (of EKS node group). Cluster Autoscaler won’t increase number of nodes beyond this maximum specified in the ASG

```file
autoscaling/compute/overprovisioning/setup/deployment-pause.yaml
```

Apply the updates to your cluster:

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k /workspace/modules/autoscaling/compute/overprovisioning/setup
```