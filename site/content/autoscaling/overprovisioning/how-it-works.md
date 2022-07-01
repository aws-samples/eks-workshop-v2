---
title: "How over provisioning works?"
weight: 30
chapter: false
---

## Introduction to Pod Priorities

Pod’s can be assigned priorities relative to other pods. The kuberentes scheduler will use this to preempt other pods with lower priority to accommodate higher priority pods.

PriorityClasses with Priority Values are created and assigned to Pods. A default PriorityClass can be assigned to namespaces. Shown below is an example of **PriorityClass** Definition and how it is used in the PodSpec using **PriorityClassName**.


### Priority Class

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
   name: high-priority
value: 1000
globalDefault: false
description: "Priority class used for high priority pods only."
```
> **Note**: **`globalDefault`** field is used to assign priority for all pods in a cluster that don't have Priority Assigned.

### PodSpec with PriorityClassName Specified

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

## How CA over provisioning works?

Here is the flow of how over provisioning works

* In this workshop a PriorityClass with priority value **“-1"** is created and assign to empty [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pods (Deployments). The empty Pause containers act as placeholders. 

* A default PriorityClass is created priority valuel **“0”.** The PriorityClass is assigned globally for the cluster, so any deployment without a PriorityClassName will bet assigned a default priority

* When a critical application pod is scheduled (with higher Priority or Default Priority greater than "-1") empty Pause containers get evicted and critical application pods get provisioned immediately. 

* Since there are **Pending** (Pause Container) pods in the cluster Cluster Autoscaler will kick in and provision additional kubernetes worker nodes based on **ASG configuration (`--max-size`)**.


How much over provisioning is needed can be controlled by 

1. The number of Pause Pods (**replicas**) with necessary **CPU and memory** specified deployed
2. The maximum size of ASG (The command below shows the ASG configuration)

>**Note**: This estimate is done manually, The [Horizontal Cluster Proportional Autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler) can be used to scale placeholder Pause container Pods (Deployments) to scale with the size of the cluster.

```bash
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

>**Note**: The **`—max-size`** dictates how many nodes the Cluster Autoscaler will provision

{{< output >}}
+-----------------------------------------------------------+
|                 DescribeAutoScalingGroups                 |
+-------------------------------------------+----+----+-----+
|  eks-1eb9b447-f3c1-0456-af77-af0bbd65bc9f |  3 |  4 |  3  |
+-------------------------------------------+----+----+-----+
{{< /output >}}
