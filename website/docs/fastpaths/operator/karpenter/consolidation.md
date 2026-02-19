---
title: "Disruption (Consolidation)"
sidebar_position: 50
---

Karpenter automatically discovers nodes that are eligible for disruption and spins up replacements when needed. This can happen for three different reasons:

- **Expiration**: By default, Karpenter automatically expires instances after 720h (30 days), forcing a recycle allowing nodes to be kept up to date.
- **Drift**: Karpenter detects changes in configuration (such as the `NodePool` or `NodeClass`) to apply necessary changes
- **Consolidation**: A critical feature for operating compute in a cost-effective manner, Karpenter will optimize our cluster's compute on an on-going basis. For example, if workloads are running on under-utilized compute instances, it will consolidate them to fewer instances.

Disruption is configured through the `disruption` block in a `NodePool`. You can see below the portion of the `general-purpose` NodePool configuration policy that Auto Mode has configured for you.

```json
  disruption:
    budgets:
    - nodes: 10%
    consolidateAfter: 30s
    consolidationPolicy: WhenEmptyOrUnderutilized
```

1. `budget` is set to a custom value so that only a specified % of nodes get disturbed at the same time to minimize any adverse impact on your workload.
2. `consolidateAfter` specifies a wait time before initiating the consolidation process.
3. The `WhenEmptyOrUnderutilized` policy enables Karpenter to replace nodes when they are either empty or underutilized.

You can see the NodePool configuration using the following command and check out the disruption configuration.

```bash
$ kubectl get nodepools general-purpose -o yaml | yq .spec.disruption
```

The `consolidationPolicy` value of `WhenEmptyOrUnderutilized` will consolidate nodes to optimize packing after `consolidateAfter` (30s here) with a budget that allow to replace 10% of the node at a time. There are other values possible, for example `consolidationPolicy` can also be set to `WhenEmpty`, which restricts disruptions only to nodes that contain no workload pods. Learn more about Disruption on the [Karpenter docs](https://karpenter.sh/docs/concepts/disruption/#consolidation).

Scaling out infrastructure is only one side of the equation for operating compute infrastructure in a cost-effective manner. We also need to be able to optimize on an on-going basis such that, for example, workloads running on under-utilized compute instances are compacted to fewer instances. This improves the overall efficiency of how we run workloads on the compute, resulting in less overhead and lower costs.

Let's explore how to trigger automatic consolidation when `disruption` is set to `consolidationPolicy: WhenEmptyOrUnderutilized`:

1. Scale the `inflate` workload from 5 to 12 replicas, triggering Karpenter to provision additional capacity
2. Scale down the workload back down to 5 replicas
3. Observe Karpenter consolidating the compute

Scale our `inflate` workload again to consume more resources:

```bash
$ kubectl scale -n other deployment/inflate --replicas 12
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

This changes the total memory request for this deployment to around 12Gi, which when adjusted to account for the roughly 600Mi reserved for the kubelet on each node means that this will fit on 2 instances of type `m5.large`:

```bash
$ kubectl get nodes -L beta.kubernetes.io/instance-type -L kubernetes.io/arch -L kubernetes.io/os --sort-by=.metadata.creationTimestamp
NAME                  STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   20h     v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0e209b70f1d2dfae0   Ready    <none>   17h     v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   90m     v1.33.4-eks-e386d34   m5a.large       amd64   linux
i-076a7c45e5f8e5f11   Ready    <none>   7m12s   v1.33.4-eks-e386d34   m5a.large       amd64   linux
```

Next, scale the number of replicas back down to 5:

```bash wait=90
$ kubectl scale -n other deployment/inflate --replicas 5
```

We can check the Karpenter events to get an idea of what actions it took in response to our scaling in the deployment. Wait about 5-10 seconds before running the following command:

```bash hook=grep
$ kubectl events | grep -i 'disruption'

3m39s       Normal    DisruptionBlocked                nodeclaim/general-purpose-5c74h   Node is nominated for a pending pod
3m42s       Normal    DisruptionLaunching              nodeclaim/general-purpose-l6dpl   Launching NodeClaim: Underutilized
3m42s       Normal    DisruptionWaitingReadiness       nodeclaim/general-purpose-l6dpl   Waiting on readiness to continue disruption
3m39s       Normal    DisruptionBlocked                nodeclaim/general-purpose-l6dpl   Nodeclaim does not have an associated node
18m         Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Nodeclaim does not have an associated node
4m38s       Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Node is nominated for a pending pod
3m20s       Normal    DisruptionTerminating            nodeclaim/general-purpose-m6gjm   Disrupting NodeClaim: Underutilized
2m29s       Normal    DisruptionBlocked                nodeclaim/general-purpose-m6gjm   Node is deleting or marked for deletion
4m38s       Normal    DisruptionTerminating            nodeclaim/general-purpose-nhtc7   Disrupting NodeClaim: Underutilized
4m28s       Normal    DisruptionBlocked                nodeclaim/general-purpose-nhtc7   Node is deleting or marked for deletion
4m38s       Normal    DisruptionBlocked                node/i-076a7c45e5f8e5f11          Node is nominated for a pending pod
3m20s       Normal    DisruptionTerminating            node/i-076a7c45e5f8e5f11          Disrupting Node: Underutilized
2m29s       Normal    DisruptionBlocked                node/i-076a7c45e5f8e5f11          Node is deleting or marked for deletion
3m39s       Normal    DisruptionBlocked                node/i-0a78dba9f62f5e0e4          Node is nominated for a pending pod
3m19s       Normal    DisruptionBlocked                node/i-0e1f072dc32194cc7          Node is nominated for a pending pod
4m38s       Normal    DisruptionTerminating            node/i-0e209b70f1d2dfae0          Disrupting Node: Underutilized
4m28s       Normal    DisruptionBlocked                node/i-0e209b70f1d2dfae0          Node is deleting or marked for deletion
```

The output will show Karpenter identifying specific nodes to cordon, drain and then terminate:

This will result in the Kubernetes scheduler placing any pods on those nodes on the remaining capacity, and now we can see less number of nodes in the cluster.

```bash
$ kubectl get nodes -L beta.kubernetes.io/instance-type -L kubernetes.io/arch -L kubernetes.io/os --sort-by=.metadata.creationTimestamp

NAME                  STATUS   ROLES    AGE    VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   21h    v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   104m   v1.33.4-eks-e386d34   m5a.large       amd64   linux
i-0e1f072dc32194cc7   Ready    <none>   6m4s   v1.33.4-eks-e386d34   c6a.large       amd64   linux
```

Karpenter can also further consolidate if a node can be replaced with a cheaper variant in response to workload changes. This can be demonstrated by scaling the `inflate` deployment replicas down to 1, with a total memory request of around 1Gi:

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

We can check the Karpenter logs and see what actions the controller took in response:

```bash test=false
$ kubectl events | grep -i 'disruption'
```

The output will show Karpenter consolidating the workloads by removing underutilized nodes in the NodePool.

This concludes the introduction to EKS Auto Mode's autoscaling capabilities. Though we used the default NodePool and NodeClass configuration that Auto Mode provides, you may also configure custom NodePool and NodeClass resources in your cluster to fit your specific needs.
