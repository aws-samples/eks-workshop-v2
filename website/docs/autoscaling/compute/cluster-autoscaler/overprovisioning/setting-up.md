---
title: "Setting up Over-Provisioning"
sidebar_position: 35
---

It's considered a best practice to create appropriate `PriorityClass` for your applications. Now, let's create a global default priority class using the field `globalDefault:true`. This default `PriorityClass` will be assigned pods/deployments that don’t specify a `PriorityClassName`.

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml
```

We'll also create `PriorityClass` that will be assigned to pause pods used for over-provisioning with priority value `-1`.

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml
```

Pause pods make sure there are enough nodes that are available based on how much over provisioning is needed for your environment. Keep in mind the `—max-size` parameter in ASG (of EKS node group). Cluster Autoscaler won’t increase number of nodes beyond this maximum specified in the ASG

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/deployment-pause.yaml
```

In this case we're going to schedule a single pause pod requesting `6.5Gi` of memory, which means it will consume almost an entire `m5.large` instance. This will result in us always having 2 "spare" worker nodes available.

Apply the updates to your cluster:

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
priorityclass.scheduling.k8s.io/default created
priorityclass.scheduling.k8s.io/pause-pods created
deployment.apps/pause-pods created
$ kubectl rollout status -n other deployment/pause-pods --timeout 300s
```

Once this completes the pause pods will be running:

```bash
$ kubectl get pods -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-7f7669b6d7-v27sl   1/1     Running   0          5m6s
pause-pods-7f7669b6d7-v7hqv   1/1     Running   0          5m6s
```

An we can see additional nodes have been provisioned by CA:

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-111.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-133.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   vVAR::KUBERNETES_NODE_VERSION
```

These two nodes are not running any workloads except for our pause pods, which will be evicted when "real" workloads are scheduled.
