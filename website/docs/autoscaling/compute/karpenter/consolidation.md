---
title: "Consolidation"
sidebar_position: 50
---

Scaling out infrastructure is only one side of the equation for operating compute infrastructure in a cost-effective manner. We also need to be able to optimize on an on-going basis such that, for example, workloads running on under-utilized compute instances are compacted to fewer instances. This improves the overall efficiency of how we run workloads on the compute, resulting in less overhead and lower costs.

Karpenter offers two main ways this can be accomplished:

1. Leverage the `ttlSecondsUntilExpired` property of Provisioners so that instances are regularly recycled, which will result in compaction of workloads indirectly
2. Since v0.15 its possible to use the **Consolidation** feature, which will actively attempt to compact under-utilized workloads

We'll be focusing on option 2 in this lab, and to demonstrate we'll be performing these steps:

1. Adjust the Provisioner created in the previous section to enable consolidation
2. Scale the `inflate` workload from 5 to 12 replicas, triggering Karpenter to provision additional capacity
3. Scale down the workload back down to 5 replicas
4. Observe Karpenter consolidating the compute

Now, let's update the Provisioner to enable consolidation:

```kustomization
modules/autoscaling/compute/karpenter/consolidation/provisioner.yaml
Provisioner/default
```

Let's apply this update:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/consolidation
```

Now, let's scale our `inflate` workload again to consume more resources:

```bash
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

This changes the total memory request for this deployment to around 12Gi, which when adjusted to account for the roughly 600Mi reserved for the kubelet on each node means that this will fit on 2 instances of type `m5.large`:

```bash
$ kubectl get nodes -l type=karpenter
```

Next, scale the number of replicas back down to 5:

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

We can check the Karpenter logs to get an idea of what actions it took in response to our scaling in the deployment:

```bash test=false
$ kubectl -n karpenter logs deployment/karpenter -c controller | grep 'deprovisioning via consolidation delete' -A 2
```

The output will show Karpenter identifying specific nodes to cordon, drain and then terminate:

```text
2023-07-20T22:06:33.926Z        INFO    controller.deprovisioning       deprovisioning via consolidation delete, terminating 1 nodes ip-10-42-159-233.us-west-2.compute.internal/m5.large/on-demand  {"commit": "5a7faa0-dirty"}
2023-07-20T22:06:33.984Z        INFO    controller.termination  cordoned node   {"commit": "5a7faa0-dirty", "node": "ip-10-42-159-233.us-west-2.compute.internal"}
2023-07-20T22:06:34.263Z        INFO    controller.termination  deleted node    {"commit": "5a7faa0-dirty", "node": "ip-10-42-159-233.us-west-2.compute.internal"}
```

This will result in the Kubernetes scheduler placing any Pods on those nodes on the remaining capacity, and now we can see that Karpenter is managing a total of 1 node:

```bash
$ kubectl get nodes -l type=karpenter
```

Karpenter can also further consolidate if a node can be replaced with a cheaper variant in response to workload changes. This can be demonstrated by scaling the `inflate` deployment replicas down to 1, with a total memory request of around 1Gi:

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

We can check the Karpenter logs and see what actions the controller took in response: 

```bash test=false
$ kubectl -n karpenter logs deployment/karpenter -c controller | grep 'deprovisioning via consolidation replace' -A 2
```

The output will show Karpenter consolidating via replace, replacing the m5.large node with the cheaper c5.large instance type defined in the Provisioner:

```text
2023-07-20T22:08:54.965Z        INFO    controller.deprovisioning       deprovisioning via consolidation replace, terminating 1 nodes ip-10-42-83-198.us-west-2.compute.internal/m5.large/on-demand and replacing with on-demand node from types c5.large   {"commit": "5a7faa0-dirty"}
2023-07-20T22:08:54.980Z        INFO    controller.deprovisioning       launching node with 1 pods requesting {"cpu":"125m","memory":"1Gi","pods":"3"} from types c5.large  {"commit": "5a7faa0-dirty", "provisioner": "default"}
2023-07-20T22:08:55.229Z        DEBUG   controller.deprovisioning.cloudprovider discovered launch template      {"commit": "5a7faa0-dirty", "provisioner": "default", "launch-template-name": "Karpenter-eks-workshop-16555401392435391284"}
```

Since the total memory request with 1 replica is much lower around 1Gi, it would be more efficient to run it on the cheaper c5.large instance type with 4GB of memory. Once the node is replaced, we can check the metadata on the new node and confirm the instance type is the c5.large: 

```bash
$ kubectl get nodes -l type=karpenter -o jsonpath="{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{'\n'}{end}"
c5.large
```
