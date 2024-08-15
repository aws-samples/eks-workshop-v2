
---
title: "Provisioning Node Pools for LLM Workloads"
sidebar_position: 20
---

In this lab, we'll use Karpenter to provision the Inferentia-2 nodes necessary for handling the Llama2 chatbot workload. As an autoscaler, Karpenter creates the resources required to run machine learning workloads and distribute traffic efficiently.

:::tip
To learn more about Karpenter, check out the [Karpenter module](../../autoscaling/compute/karpenter/index.md) in this workshop.
:::

Karpenter has already been installed in our EKS Cluster and runs as a deployment:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

As we did in a previous lab, we need to update our EKS IAM mappings to allow Karpenter nodes to join the cluster:

```bash
$ eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME \
    --region $AWS_REGION --arn $KARPENTER_ARN \
    --group system:bootstrappers --group system:nodes \
    --username system:node:{{EC2PrivateDNSName}}
```

Since the Ray Cluster creates head and worker pods with different specifications for handling various EC2 families, we'll create two separate node pools to handle the workload demands.

Here's the first Karpenter `NodePool` that will provision one `Head Pod` on `x86 CPU` instances:

```file
manifests/modules/aiml/chatbot/nodepool/nodepool-x86.yaml
```

Compared to the previous lab, there are more specifications defining the unique constraints of the `Head Pod`, such as specifying an instance family of `r5`, `m5`, and `c5` nodes.

This secondary `NodePool` will provision `Ray Workers` on `Inf2.48xlarge` instances:

```file
manifests/modules/aiml/chatbot/nodepool/nodepool-inf2.yaml
```

Similarly, there are specifications matching the requirements of the `Ray Workers` that will run on instances from the `Inf2` family.

Both of these defined node pools will allow Karpenter to properly schedule nodes and handle the workload demands of the Ray Cluster.

Apply the `NodePool` and `EC2NodeClass` manifests for both pools:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/inferentia-inf2 created
ec2nodeclass.karpenter.k8s.aws/x86-cpu-karpenter created
nodepool.karpenter.sh/inferentia-inf2 created
nodepool.karpenter.sh/x86-cpu-karpenter created
```

Once properly deployed, check for the node pools:

```bash
$ kubectl get nodepool
NAME                NODECLASS
inferentia-inf2     inferentia-inf2
x86-cpu-karpenter   x86-cpu-karpenter
```

As seen from the above command, both node pools have been properly provisioned, allowing Karpenter to allocate new nodes into the newly created pools as needed.
