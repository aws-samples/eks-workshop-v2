---
title: "Provisioning compute"
sidebar_position: 30
---

In this lab, we'll use Karpenter to provision AWS Neuron nodes specifically designed for accelerated machine learning inference. Inferentia and Trainium are AWS's purpose-built ML accelerators that provide high performance and cost-effectiveness for running inference workloads like our Mistral-7B model.

:::tip
To learn more about Karpenter, check out the [Karpenter module](../../fundamentals/compute/karpenter/index.md) in this workshop.
:::

Karpenter has already been installed in our EKS cluster and runs as a Deployment:

```bash
$ kubectl get deployment karpenter -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

Let's review the configuration for the Karpenter NodePool that we'll be using to provision Neuron instances:

::yaml{file="manifests/modules/aiml/chatbot/nodepool.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. We're configuring the NodePool to use either `inf2.xlarge` or `trn1.2xlarge` instance types based on what is available in the region we're running.
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `karpenter.k8s.aws/instance-type` to limit to a subset of specific instance types. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes).
3. A Taint defines a specific set of properties that allow a node to repel a set of Pods. This property works with its matching label, a Toleration. Both tolerations and taints work together to ensure that Pods are properly scheduled onto the appropriate nodes. You can learn more about the other properties in [this resource](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).
4. A NodePool can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular NodePool, providing a cap on the total compute.

Let's create the NodePool:

```bash
$ cat ~/environment/eks-workshop/modules/aiml/chatbot/nodepool.yaml \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/neuron created
nodepool.karpenter.sh/neuron created
```

Once properly deployed, check for the NodePools:

```bash
$ kubectl get nodepool
NAME         NODECLASS    NODES   READY   AGE
neuron       neuron       0       True    31s
```

As seen from the above command the NodePool has been properly provisioned, allowing Karpenter to provision new nodes as needed. When we deploy our ML workload in the next step, Karpenter will automatically create the required Neuron instances based on the resource requests and limits we specify.
