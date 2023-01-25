---
title: "How it works"
sidebar_position: 30
---

Pods can be assigned priorities relative to other Pods. The Kubernetes scheduler will use this to pre-empt other Pods with lower priority to accommodate higher priority Pods. `PriorityClass` resources with priority values are created and assigned to Pods, and a default `PriorityClass` can be assigned to a namespace.

Below is an example of a priority class that would allow a Pod to take relatively high priority over other Pods:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
   name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority Pods only."
```

This is an example of a Pod specification that uses the above priority class:

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

The documentation for [Pod Priority and Pre-emption](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/) explains how this works in detail.

How can we apply this to accomplish over-provisioning the compute in our EKS cluster?

* A priority class with priority value **“-1"** is created and assign to empty [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pods. The empty "pause" containers act as placeholders.

* A default priority class is created priority value **“0”.** This is assigned globally for a cluster, so any deployment without a priority class will bet assigned this default priority.

* When a genuine workload is scheduled the empty placeholder containers get evicted and the application Pods get provisioned immediately.

* Since there are **Pending** (Pause Container) Pods in our cluster, the Cluster Autoscaler will kick in and provision additional Kubernetes worker nodes based on **ASG configuration (`--max-size`)** that is associated with the EKS node group.

How much over provisioning is needed can be controlled by:

1. The number of pause Pods (**replicas**) with necessary **CPU and memory** resource requests
2. The maximum number of nodes in the EKS node group (`maxsize`)
