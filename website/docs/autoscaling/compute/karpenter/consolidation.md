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
autoscaling/compute/karpenter/consolidation/provisioner.yaml
Provisioner/default
```

Let's apply this update:

```bash
$ kubectl apply -k /workspace/modules/autoscaling/compute/karpenter/consolidation
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
$ kubectl -n karpenter logs deployment/karpenter -c controller | grep Consolidating -A 2
```

The output will show Karpenter identifying specific nodes to cordon, drain and then terminate:

```
2022-09-06T19:30:06.285Z        INFO    controller.consolidation        Consolidating via Delete, terminating 1 nodes ip-192-168-159-233.us-west-2.compute.internal/m5.large    {"commit": "b157d45"}
2022-09-06T19:30:06.341Z        INFO    controller.termination  Cordoned node   {"commit": "b157d45", "node": "ip-192-168-159-233.us-west-2.compute.internal"}
2022-09-06T19:30:07.441Z        INFO    controller.termination  Deleted node    {"commit": "b157d45", "node": "ip-192-168-159-233.us-west-2.compute.internal"}
```

This will result in the Kubernetes scheduler placing any Pods on those nodes on the remaining capacity, and now we can see that Karpenter is managing a total of 1 node:

```bash
$ kubectl get nodes -l type=karpenter
```
