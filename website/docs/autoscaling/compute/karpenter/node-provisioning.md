---
title: "Automatic Node Provisioning"
sidebar_position: 40
---

We'll start putting Karpenter to work by examining how it can dynamically provision appropriately sized EC2 instances depending on the needs of Pods that cannot be scheduled at any given time. This can reduce the amount of unused compute resources in an EKS cluster.

The NodePool created in the previous section expressed specific instance types that Karpenter was allowed to use, lets take a look at those instance types:

| Instance Type | vCPU | Memory | Price |
|---------------|------|--------|-------|
| c5.large | 2 | 4GB | + |
| m5.large | 2 | 8GB | ++ |
| r5.large | 2 | 16GB | +++ |
| m5.xlarge | 4 | 16GB | ++++ |

Let's create some Pods and see how Karpenter adapts. Currently there are no nodes managed by Karpenter:

```bash
$ kubectl get node -l type=karpenter
No resources found
```

The following `Deployment` uses a simple `pause` container image which has a resource request of `memory: 1Gi`, which we'll use to predictably scale the cluster. Note that the `nodeSelector` is set to `type: karpenter`, which requires the pods to only be scheduled on nodes with that label provisioned by our Karpenter `NodePool`. We'll start with `0` replicas:

```file
manifests/modules/autoscaling/compute/karpenter/scale/deployment.yaml
```

:::info What's a pause container?
You'll notice in this example we're using the image:

`public.ecr.aws/eks-distro/kubernetes/pause`

This is a small container that will consume no real resources and starts quickly, which makes it great for demonstrating scaling scenarios. We'll be using this for many of the examples in this particular lab.
:::

Apply this deployment:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/scale
deployment.apps/inflate created
```

Now let's deliberately scale this deployment to demonstrate that Karpenter is making optimized decisions. Since we've requested 1Gi of memory, if we scale the deployment to 5 replicas that will request a total of 5Gi of memory.

Before we proceed, what instance from the table above do you think Karpenter will end up provisioning? Which instance type would you want it to?

Scale the deployment:

```bash hook=karpenter-deployment
$ kubectl scale -n other deployment/inflate --replicas 5
```

Because this operation is creating one or more new EC2 instances it will take a while, you can use `kubectl` to wait until its done with this command:

```bash
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

Once all of the Pods are running, lets see what instance type it selecting:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'launched nodeclaim' | jq '.'
```

You should see output that indicates the instance type and the purchase option:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:32:00.413Z",
  "logger": "controller.nodeclaim.lifecycle",
  "message": "launched nodeclaim",
  "commit": "1072d3b",
  "nodeclaim": "default-xxm79",
  "nodepool": "default",
  "provider-id": "aws:///us-west-2a/i-0bb8a7e6111d45591",
  # HIGHLIGHT
  "instance-type": "m5.large",
  "zone": "us-west-2a",
  # HIGHLIGHT
  "capacity-type": "on-demand",
  "allocatable": {
    "cpu": "1930m",
    "ephemeral-storage": "17Gi",
    "memory": "6903Mi",
    "pods": "29",
    "vpc.amazonaws.com/pod-eni": "9"
  }
}
```

The Pods that we scheduled will fit nicely in to an EC2 instance with 8GB of memory, and since Karpenter will always prioritize the lowest price instance type for on-demand instances, it will select `m5.large`.

:::info
There are certain cases where a different instance type might be selected other than the lowest price, for example if that cheapest instance type has no remaining capacity available in the region you're working in
:::

We can also check the metadata added to the node by Karpenter:

```bash
$ kubectl get node -l type=karpenter -o jsonpath='{.items[0].metadata.labels}' | jq '.'
```

This output will show the various labels that are set, for example the instance type, purchase option, availability zone etc:

```json
{
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "1911afb91fc78905500a801c7b5ae731",
  "karpenter.k8s.aws/instance-category": "m",
  "karpenter.k8s.aws/instance-cpu": "2",
  "karpenter.k8s.aws/instance-family": "m5",
  "karpenter.k8s.aws/instance-generation": "5",
  "karpenter.k8s.aws/instance-hypervisor": "nitro",
  "karpenter.k8s.aws/instance-memory": "8192",
  "karpenter.k8s.aws/instance-pods": "29",
  "karpenter.k8s.aws/instance-size": "large",
  "karpenter.sh/capacity-type": "on-demand",
  "karpenter.sh/initialized": "true",
  "karpenter.sh/provisioner-name": "default",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-100-64-10-200.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.ebs.csi.aws.com/zone": "us-west-2a",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "type": "karpenter",
  "vpc.amazonaws.com/has-trunk-attached": "true"
}
```

This simple examples illustrates the fact that Karpenter can dynamically select the right instance type based on the resource requirements of the workloads that require compute capacity. This differs fundamentally from a model oriented around node pools, such as Cluster Autoscaler, where the instance types within a single node group must have consistent CPU and memory characteristics.
