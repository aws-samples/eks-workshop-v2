---
title: "Disruption (Consolidation)"
sidebar_position: 50
---

Karpenter automatically discovers nodes that are eligible for disruption and spins up replacements when needed. This can happen for three different reasons:

- **Expiration**: By default, Karpenter automatically expires instances after 720h (30 days), forcing a recycle allowing nodes to be kept up to date.
- **Drift**: Karpenter detects changes in configuration (such as the `NodePool` or `EC2NodeClass`) to apply necessary changes
- **Consolidation**: A critical feature for operating compute in a cost-effective manner, Karpenter will optimize our cluster's compute on an on-going basis. For example, if workloads are running on under-utilized compute instances, it will consolidate them to fewer instances.

Disruption is configured through the `disruption` block in a `NodePool`. You can see highlighted below the policy thats already configured in our `NodePool`.

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.spec.expireAfter,spec.disruption"}

1. `expireAfter` is set to a custom value so that nodes are terminated automatically after 72 hours
2. The `WhenEmptyOrUnderutilized` policy enables Karpenter to replace nodes when they are either empty or underutilized

The `consolidationPolicy` can also be set to `WhenEmpty`, which restricts disruption only to nodes that contain no workload pods. Learn more about Disruption on the [Karpenter docs](https://karpenter.sh/docs/concepts/disruption/#consolidation).

Scaling out infrastructure is only one side of the equation for operating compute infrastructure in a cost-effective manner. We also need to be able to optimize on an on-going basis such that, for example, workloads running on under-utilized compute instances are compacted to fewer instances. This improves the overall efficiency of how we run workloads on the compute, resulting in less overhead and lower costs.

Let's explore how to trigger automatic consolidation when `disruption` is set to `consolidationPolicy: WhenUnderutilized`:

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
$ kubectl get nodes -l type=karpenter --label-columns node.kubernetes.io/instance-type
NAME                                         STATUS   ROLES    AGE     VERSION               INSTANCE-TYPE
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   3m30s   vVAR::KUBERNETES_NODE_VERSION     m5.large
ip-10-42-9-102.us-west-2.compute.internal    Ready    <none>   14m     vVAR::KUBERNETES_NODE_VERSION     m5.large
```

Next, scale the number of replicas back down to 5:

```bash wait=90
$ kubectl scale -n other deployment/inflate --replicas 5
```

We can check the Karpenter logs to get an idea of what actions it took in response to our scaling in the deployment. Wait about 5-10 seconds before running the following command:

```bash hook=grep
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'disrupting node(s)' | jq '.'
```

The output will show Karpenter identifying specific nodes to cordon, drain and then terminate:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:47:05.659Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

This will result in the Kubernetes scheduler placing any pods on those nodes on the remaining capacity, and now we can see that Karpenter is managing a total of 1 node:

```bash
$ kubectl get nodes -l type=karpenter
ip-10-42-44-164.us-west-2.compute.internal   Ready    <none>   6m30s   vVAR::KUBERNETES_NODE_VERSION   m5.large
```

Karpenter can also further consolidate if a node can be replaced with a cheaper variant in response to workload changes. This can be demonstrated by scaling the `inflate` deployment replicas down to 1, with a total memory request of around 1Gi:

```bash
$ kubectl scale -n other deployment/inflate --replicas 1
```

We can check the Karpenter logs and see what actions the controller took in response:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter -f | jq '.'
```

:::tip
The previous command includes the flag "-f" for follow, allowing us to watch the logs as they happen. Consolidation to a smaller node takes less than one minute. Watch the logs to how the Karpenter controller behaves.
:::

The output will show Karpenter consolidating via replace, replacing the m5.large node with the cheaper c5.large instance type defined in the Provisioner:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:50:23.249Z",
  "logger": "controller",
  "message": "disrupting node(s)",
  "commit": "1072d3b",
  [...]
}
```

Since the total memory request with 1 replica is much lower around 1Gi, it would be more efficient to run it on the cheaper c5.large instance type with 4GB of memory. Once the node is replaced, we can check the metadata on the new node and confirm the instance type is the c5.large:

```bash
$ kubectl get nodes -l type=karpenter -o jsonpath="{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{'\n'}{end}"
c5.large
```
