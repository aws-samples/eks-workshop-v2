---
title: "How it works"
sidebar_position: 30
---

Pods can be assigned priorities relative to other pods. The Kubernetes scheduler will use this to pre-empt other pods with lower priority to accommodate higher priority pods. `PriorityClass` resources with priority values are created and assigned to pods, and a default `PriorityClass` can be assigned to a namespace.

Below is an example of a priority class that would allow a pod to take relatively high priority over other pods:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
   name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority pods only."
```

This is an example of a pod specification that uses the above priority class:

```yaml
apiVersion: v1
kind: Pod
metadata:
   name: nginx
   labels:
      env: test
spec:
   containers:
   - name: nginx
     image: nginx
     imagePullPolicy: IfNotPresent
   priorityClassName: high-priority # Priority Class specified
```

The documentation for [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) explains how this works in detail.

How can we apply this to accomplish over-provisioning the compute in our EKS cluster?

* A priority class with priority value **“-1"** is created and assign to empty [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) pods. The empty "pause" containers act as placeholders.

* A default priority class is created priority valuel **“0”.** This is assigned globally for the cluster, so any deployment without a priority class will bet assigned this default priority.

* When a genuine workload is scheduled the empty placeholder containers get evicted and the application pods get provisioned immediately.

* Since there are **Pending** (Pause Container) pods in the cluster Cluster Autoscaler will kick in and provision additional kubernetes worker nodes based on **ASG configuration (`--max-size`)** that is associated with EKS NodeGroup.

How much over provisioning is needed can be controlled by:

1. The number of pause pods (**replicas**) with necessary **CPU and memory** resource requests
2. The maximum number of nodes in the EKS node group (`maxsize`)