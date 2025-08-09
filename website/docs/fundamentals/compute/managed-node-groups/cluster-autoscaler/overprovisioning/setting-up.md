---
title: "Setting up Over-Provisioning"
sidebar_position: 35
---

To implement over-provisioning effectively, it's considered a best practice to create appropriate `PriorityClass` resources for your applications. Let's begin by creating a global default priority class using the `globalDefault: true` field. This default `PriorityClass` will be assigned to pods and deployments that don't specify a `PriorityClassName`.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml" paths="value,globalDefault"}

1. The value is specified in the required `value` field. The higher the value, the higher the priority.
2. The `globalDefault` field indicates that the value of this PriorityClass should be used for Pods without a priorityClassName.

Next, we'll create a `PriorityClass` specifically for the pause pods used in over-provisioning, with a priority value of `-1`.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml" paths="value"}

1. Priority value of "-1" allows the empty "pause" containers to act as placeholders. When a genuine workload is scheduled, the empty placeholder containers are evicted, allowing the application Pods to be provisioned immediately.

Pause pods play a crucial role in ensuring that there are enough available nodes based on the amount of over-provisioning needed for your environment. It's important to keep in mind the `--max-size` parameter in the ASG of the EKS node group, as the Cluster Autoscaler won't increase the number of nodes beyond this maximum specified in the ASG.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/deployment-pause.yaml" paths="spec.replicas,spec.template.spec.priorityClassName"}

1. Deploy 2 replicas of the pause pod
2. Use the priority class we created previously

Since these pods are requesting `6.5Gi` of memory each will consume almost an entire `m5.large` instance, resulting in two "spare" worker nodes being available at all times.

Let's apply these updates to our cluster:

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
priorityclass.scheduling.k8s.io/default created
priorityclass.scheduling.k8s.io/pause-pods created
deployment.apps/pause-pods created
$ kubectl rollout status -n other deployment/pause-pods --timeout 300s
```

Once this process completes, the pause pods will be running:

```bash
$ kubectl get pods -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-7f7669b6d7-v27sl   1/1     Running   0          5m6s
pause-pods-7f7669b6d7-v7hqv   1/1     Running   0          5m6s
```

We can now observe that additional nodes have been provisioned by the Cluster Autoscaler:

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

These two additional nodes are not running any workloads except for our pause pods, which will be evicted when "real" workloads are scheduled.
