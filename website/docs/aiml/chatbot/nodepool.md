---
title: "Provisioning Node Pools for LLM Workloads"
sidebar_position: 20
---

In this lab, we'll use Karpenter to provision the Trainium-1 nodes necessary for handling the Mistral-7B chatbot workload. As an autoscaler, Karpenter creates the resources required to run machine learning workloads and distribute traffic efficiently.

:::tip
To learn more about Karpenter, check out the [Karpenter module](../../autoscaling/compute/karpenter/index.md) in this workshop.
:::

Karpenter has already been installed in our EKS Cluster and runs as a deployment:

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

Since the Ray Cluster creates head and worker pods with different specifications for handling various EC2 families, we'll create two separate node pools to handle the workload demands.

Here's the first Karpenter `NodePool` that will provision one `Head Pod` on `x86 CPU` instances:

::yaml{file="manifests/modules/aiml/chatbot/nodepool/nodepool-x86.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.limits"}

1. We're asking the `NodePool` to start all new nodes with a Kubernetes label `type: karpenter`, which will allow us to specifically target Karpenter nodes with pods for demonstration purposes. Since there are multiple nodes being autoscaled by Karpenter, there are additional labels added such as `instanceType: mixed-x86` to indicate that this Karpenter node should be assigned to `x86-cpu-karpenter` pool.
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `karpenter.k8s.aws/instance-family` to limit to a subset of specific instance types. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes). Compared to the previous lab, there are more specifications defining the unique constraints of the `Head Pod`, such as defining an instance family of `r5`, `m5`, and `c5` nodes.
3. A `NodePool` can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular `NodePool`, providing a cap on the total compute.

This secondary `NodePool` will provision `Ray Workers` on `trn1.2xlarge` instances:

::yaml{file="manifests/modules/aiml/chatbot/nodepool/nodepool-trn1.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements,spec.template.spec.taints,spec.limits"}

1. We're asking the `NodePool` to start all new nodes with a Kubernetes label `provisionerType: Karpenter`, which will allow us to specifically target Karpenter nodes with pods for demonstration purposes. Since there are multiple nodes being autoscaled by Karpenter, there are additional labels added such as `instanceType: trn1.2xlarge` to indicate that this Karpenter node should be assigned to `trainium-trn1` pool.
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this example, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `karpenter.k8s.aws/instance-type` to limit to a subset of specific instance type. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes). In this case, there are specifications matching the requirements of the `Ray Workers` that will run on `trn1.2xlarge` instances type.
3. A `Taint` defines a specific set of properties that allow a node to repel a set of pods. This property works with its matching label, a `Toleration`. Both tolerations and taints work together to ensure that pods are properly scheduled onto the appropriate pods. You can learn more about the other properties in [this resource](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).
4. A `NodePool` can define a limit on the amount of CPU and memory managed by it. Once this limit is reached Karpenter will not provision additional capacity associated with that particular `NodePool`, providing a cap on the total compute.

Both of these defined node pools will allow Karpenter to properly schedule nodes and handle the workload demands of the Ray Cluster.

Apply the `NodePool` and `EC2NodeClass` manifests for both pools:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/trainium-trn1 created
ec2nodeclass.karpenter.k8s.aws/x86-cpu-karpenter created
nodepool.karpenter.sh/trainium-trn1 created
nodepool.karpenter.sh/x86-cpu-karpenter created
```

Once properly deployed, check for the node pools:

```bash
$ kubectl get nodepool
NAME                NODECLASS
trainium-trn1       trainium-trn1 
x86-cpu-karpenter   x86-cpu-karpenter
```

As seen from the above command, both node pools have been properly provisioned, allowing Karpenter to allocate new nodes into the newly created pools as needed.
