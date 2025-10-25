---
title: "Set up the Node Pool"
sidebar_position: 30
---

Karpenter configuration comes in the form of a `NodePool` CRD (Custom Resource Definition). A single Karpenter `NodePool` is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one `NodePool`, but for the moment we'll declare a default one.

One of the main objectives of Karpenter is to simplify the management of capacity. If you're familiar with other auto scaling solutions, you may have noticed that Karpenter takes a different approach, referred to as **group-less auto scaling**. Other solutions have traditionally used the concept of a **node group** as the element of control that defines the characteristics of the capacity provided (i.e: On-Demand, EC2 Spot, GPU Nodes, etc) and that controls the desired scale of the group in the cluster. In AWS the implementation of a node group matches with [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). Karpenter allows us to avoid complexity that arises from managing multiple types of applications with different compute needs.

We'll start by applying some custom resources used by Karpenter. First we'll create a `NodePool` that defines our general capacity requirements:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements, spec.limits"}

1. We're asking the `NodePool` to start all new nodes with a Kubernetes label `type: karpenter`, which will allow us to specifically target Karpenter nodes with pods for demonstration purposes
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `node.kubernetes.io/instance-type` to limit to a subset of specific instance types. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes). We'll work on a few more during the workshop.
3. A `NodePool` can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular `NodePool`, providing a cap on the total compute.

And we'll also need an `EC2NodeClass` which provides the specific configuration that applies to AWS:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodeclass.yaml" paths="spec.role,spec.subnetSelectorTerms,spec.tags"}

1. Assign the IAM role that will be applied to the EC2 instance provisioned by Karpenter
2. The `subnetSelectorTerms` can be used to look up the subnets where Karpenter should launch the EC2 instances. These tags were automatically set on the associated AWS infrastructure provided for the workshop. `securityGroupSelectorTerms` accomplishes the same function for the security group that will be attached to the EC2 instances.
3. We define a set of tags that will be applied to EC2 instances created which enables accounting and governance.

We've now provided Karpenter with the basic requirements in needs to start provisioning capacity for our cluster.

Apply the `NodePool` and `EC2NodeClass` with the following command:

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/nodepool \
  | envsubst | kubectl apply -f-
```

Throughout the workshop you can inspect the Karpenter logs with the following command to understand its behavior:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | jq '.'
```
