---
title: "Set up the Node Pool"
sidebar_position: 30
---

Karpenter configuration comes in the form of a `NodePool` CRD (Custom Resource Definition). A single Karpenter `NodePool` is capable of handling many different Pod shapes. Karpenter makes scheduling and provisioning decisions based on Pod attributes such as labels and affinity. A cluster may have more than one `NodePool`, but for the moment we'll declare a default one. 

One of the main objectives of Karpenter is to simplify the management of capacity. If you're familiar with other auto scaling solutions, you may have noticed that Karpenter takes a different approach, referred to as **group-less auto scaling**. Other solutions have traditionally used the concept of a **node group** as the element of control that defines the characteristics of the capacity provided (i.e: On-Demand, EC2 Spot, GPU Nodes, etc) and that controls the desired scale of the group in the cluster. In AWS the implementation of a node group matches with [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). Karpenter allows us to avoid complexity that arises from managing multiple types of applications with different compute needs.

We'll start by applying the following two CRDs, a `NodePool` and a `EC2NodeClass`. These are the requirements for Karpenter to start handling basic scaling requirements.

```file
manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml
```

:::info
We're asking the NodePool to start all new nodes with a label `type: karpenter`, which will allow us to specifically target Karpenter nodes with Pods for demonstration purposes
:::

The configuration for Karpenter is split into two parts. The first one defines the general NodePool specification. The second part is defined by the provider implementation for AWS, in our case `EC2NodeClass` and provides the specific configuration that applies to AWS. This particular NodePool configuration is quite simple, but during the workshop we'll customize it further. For the moment let's focus in a few of the settings used.

* **Requirements Section**: The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as  `kubernetes.io/os`, `karpenter.k8s.aws/instance-category` and `karpenter.k8s.aws/instance-generation` to limit to a subset of appropriate instance types. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes). We'll work on a few more during the workshop.
* **Limits section**: NodePool can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular NodePool, providing a cap on the total compute.
* **Tags**: `EC2NodeClass` can also define a set of tags that the EC2 instances will have upon creation. This helps to enable accounting and governance at the EC2 level.
* **Selectors**: The `EC2NodeClass` resource uses `securityGroupSelectorTerms` and `subnetSelectorTerms` to discover resources used to launch nodes. These tags were automatically set on the associated AWS infrastructure provided for the workshop.

Apply the `NodePool` and `EC2NodeClass` with the following command:

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/nodepool \
  | envsubst | kubectl apply -f-
```

Throughout the workshop you can inspect the Karpenter logs with the following command to understand its behavior:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | jq '.'
```
