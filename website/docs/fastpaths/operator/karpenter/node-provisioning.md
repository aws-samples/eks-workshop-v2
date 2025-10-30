---
title: "Automatic Node Provisioning"
sidebar_position: 40
---

We'll start putting Karpenter to work by examining how it can dynamically provision appropriately sized EC2 instances depending on the needs of pods that cannot be scheduled at any given time. This can reduce the amount of unused compute resources in an EKS cluster.

The NodePool inspected in the previous section expressed specific instance families that Karpenter was allowed to use. They were 

| Instance families | Generation |   OS   | Architecture |
| ----------------- | ---------- | ------ | ------------ |
| `c`, `m`, `r`     |     >4     | Linux  | amd64        |

This broad configuration provide a wide range of choices to Karpenter for selecting a right-sized instance based on the requirements.

Let's create some Pods and see how Karpenter adapts. Currently there should a couple of nodes available that are managed by Karpenter:

```bash
$ kubectl get node -l karpenter.sh/nodepool=general-purpose

NAME                  STATUS   ROLES    AGE   VERSION
i-07fd006840ed07309   Ready    <none>   17h   v1.33.4-eks-e386d34
i-0e209b70f1d2dfae0   Ready    <none>   14h   v1.33.4-eks-e386d34
```

We'll use the following Deployment to trigger Karpenter to scale out:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/automode/scale/deployment.yaml" paths="spec.replicas,spec.template.spec.containers.0.image,spec.template.spec.containers.0.resources"}

1. Initially specifies 0 replicas to run, we'll scale it up later
3. Uses a simple `pause` container image
4. Requests `1Gi` of memory for each pod

:::info What's a pause container?
You'll notice in this example we're using the image:

`public.ecr.aws/eks-distro/kubernetes/pause`

This is a small container that will consume no real resources and starts quickly, which makes it great for demonstrating scaling scenarios. We'll be using this for many of the examples in this particular lab.
:::

Apply this deployment:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/automode/scale
deployment.apps/inflate created
```

Now let's deliberately scale this deployment to demonstrate that Karpenter is making optimized decisions. Since we've requested 1Gi of memory, if we scale the deployment to 5 replicas that will request a total of 5Gi of memory.

Before we proceed, what instance from the table above do you think Karpenter will end up provisioning? Which instance type would you want it to?

Scale the deployment:

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

Because this operation is creating one or more new EC2 instances it will take a while, you can use `kubectl` to wait until its done with this command:

```bash timeout=200
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

Let's now check the action taken by Karpenter listing those events. Wait for 5-10 seconds to see the events getting listed.

```bash
$ kubectl events | grep -i 'NodeClaim'
```

You should see the output showing a new node is launched.

```
2m55s       Normal    Launched                  nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Launched, Status: Unknown -> True, Reason: Launched
2m52s       Normal    DisruptionBlocked         nodeclaim/general-purpose-5c74h   Nodeclaim does not have an associated node
2m39s       Normal    Registered                nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Registered, Status: Unknown -> True, Reason: Registered
2m36s       Normal    Initialized               nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Initialized, Status: Unknown -> True, Reason: Initialized
2m36s       Normal    Ready                     nodeclaim/general-purpose-5c74h   Status condition transitioned, Type: Ready, Status: Unknown -> True, Reason: Ready
12m         Normal    Unconsolidatable          nodeclaim/general-purpose-nhtc7   Can't replace with a cheaper node
```

Karpenter will find the most suitable instance type that is big enough to accommodate all to-be-scheduled Pods and lower in cost at the same time. 

:::info
There are certain cases where a different instance type might be selected other than the lowest price, for example if that cheapest instance type has no remaining capacity available in the region you're working in
:::

Let's again list all the available nodes in the cluster.

```bash
$ kubectl get nodes \
  -L beta.kubernetes.io/instance-type \
  -L kubernetes.io/arch \
  -L kubernetes.io/os \
  --sort-by=.metadata.creationTimestamp

NAME                  STATUS   ROLES    AGE   VERSION               INSTANCE-TYPE   ARCH    OS
i-07fd006840ed07309   Ready    <none>   20h   v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0e209b70f1d2dfae0   Ready    <none>   17h   v1.33.4-eks-e386d34   c6a.large       amd64   linux
i-0a78dba9f62f5e0e4   Ready    <none>   60m   v1.33.4-eks-e386d34   m5a.large       amd64   linux
```

You can see that the last node added to the pool is as per the `NodePool` configuration table shown earlier in this page.

Karpenter keep track of it's node through Kubernetes native object called a NodeClaim. It's an object so you can check the configuration as well:

```bash
$ kubectl get nodeclaims.karpenter.sh  -o wide
NAME                    TYPE        CAPACITY    ZONE         NODE                  READY   AGE     IMAGEID                 ID                                      NODEPOOL          NODECLASS   DRIFTED
general-purpose-dh59z   m5a.large   on-demand   us-west-2b   i-0d3ed392f96f22793   True    5m58s   ami-00e71b7a43dd16dec   aws:///us-west-2b/i-0d3ed392f96f22793   general-purpose   default
general-purpose-mw4sf   c6a.large   on-demand   us-west-2a   i-0078b61779fc13053   True    30h     ami-00e71b7a43dd16dec   aws:///us-west-2a/i-0078b61779fc13053   general-purpose   default
general-purpose-wp7wg   c6a.large   on-demand   us-west-2c   i-0c1ceaeeb6ed1bfb6   True    8m5s    ami-00e71b7a43dd16dec   aws:///us-west-2c/i-0c1ceaeeb6ed1bfb6   general-purpose   default
```

This simple examples illustrates the fact that Karpenter can dynamically select the right instance type based on the resource requirements of the workloads that require compute capacity. This differs fundamentally from a model oriented around node pools, such as Cluster Autoscaler, where the instance types within a single node group must have consistent CPU and memory characteristics.
