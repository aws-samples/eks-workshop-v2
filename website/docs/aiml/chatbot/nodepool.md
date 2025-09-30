---
title: "Provisioning compute"
sidebar_position: 30
---

In this lab, we'll use Karpenter to provision the Trainium nodes necessary for handling the Mistral-7B model workload.

:::tip
To learn more about Karpenter, check out the [Karpenter module](../../fundamentals/compute/karpenter/index.md) in this workshop.
:::

Karpenter has already been installed in our EKS Cluster and runs as a deployment:

```bash
$ kubectl get deployment karpenter -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

Lets review the configuration for the Karpenter NodePool:

::yaml{file="manifests/modules/aiml/chatbot/nodepool-trn1.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. We're asking the `NodePool` to start all new nodes with a Kubernetes label `provisionerType: Karpenter`, which will allow us to specifically target Karpenter nodes with pods for demonstration purposes. Since there are multiple nodes being autoscaled by Karpenter, there are additional labels added such as `instanceType: trn1.2xlarge` to indicate that this Karpenter node should be assigned to `trainium-trn1` pool.
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `karpenter.k8s.aws/instance-type` to limit to a subset of specific instance type. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes).
3. A `Taint` defines a specific set of properties that allow a node to repel a set of pods. This property works with its matching label, a `Toleration`. Both tolerations and taints work together to ensure that pods are properly scheduled onto the appropriate nodes. You can learn more about the other properties in [this resource](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).
4. A `NodePool` can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular `NodePool`, providing a cap on the total compute.

Create the NodePool:

```bash
$ cat ~/environment/eks-workshop/modules/aiml/chatbot/nodepool-trn1.yaml \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/trainium-trn1 created
nodepool.karpenter.sh/trainium-trn1 created
```

Once properly deployed, check for the node pools:

```bash
$ kubectl get nodepool
NAME                NODECLASS           NODES   READY   AGE
trainium-trn1       trainium-trn1       0       True    31s
```

As seen from the above command the NodePool has been properly provisioned, allowing Karpenter to provision new nodes as needed.
