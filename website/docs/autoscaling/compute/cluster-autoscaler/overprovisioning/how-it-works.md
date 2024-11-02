---
title: "How it works"
sidebar_position: 30
---

Kubernetes allows assigning priorities to Pods relative to other Pods. The Kubernetes scheduler uses these priorities to preempt lower priority Pods in order to accommodate higher priority Pods. This is achieved through `PriorityClass` resources, which define priority values that can be assigned to Pods. Additionally, a default `PriorityClass` can be assigned to a namespace.

Here's an example of a priority class that would give a Pod relatively high priority over other Pods:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority Pods only."
```

And here's an example of a Pod specification using the above priority class:

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

For a detailed explanation of how this works, refer to the Kubernetes documentation on [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/).

To apply this concept for over-provisioning compute in our EKS cluster, we can follow these steps:

1. Create a priority class with a priority value of **"-1"** and assign it to empty [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pods. These empty "pause" containers act as placeholders.

2. Create a default priority class with a priority value of **"0"**. This is assigned globally for the cluster, so any deployment without a specified priority class will be assigned this default priority.

3. When a genuine workload is scheduled, the empty placeholder containers are evicted, allowing the application Pods to be provisioned immediately.

4. Since there are **Pending** (Pause Container) Pods in the cluster, the Cluster Autoscaler will provision additional Kubernetes worker nodes based on the **ASG configuration (`--max-size`)** associated with the EKS node group.

The level of over-provisioning can be controlled by adjusting:

1. The number of pause Pods (**replicas**) and their **CPU and memory** resource requests
2. The maximum number of nodes in the EKS node group (`maxsize`)

By implementing this strategy, we can ensure that the cluster always has some spare capacity ready to accommodate new workloads, reducing the time it takes for new Pods to become schedulable.
