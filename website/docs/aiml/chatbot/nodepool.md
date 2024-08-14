---
title: "Provisioning Nodepools for LLM workloads"
sidebar_position: 20
---

The lab uses Karpenter to provision the Inferentia-2 nodes necessary for handling the Llama2 chatbot workload. As an autoscaler, Karpenter creates the necessary resources to run the machine learning workloads and distribute traffic.

:::tip
You can learn more about Karpenter in the [Karpenter module](../../autoscaling/compute/karpenter/index.md) that's provided in this workshop.
:::

Karpenter has been installed in our EKS Cluster, and runs as a deployment:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

As done in a previous lab, we need to update our EKS IAM mappings to allow Karpenter nodes to join the cluster:

```bash
$ eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME \
    --region $AWS_REGION --arn $KARPENTER_ARN \
    --group system:bootstrappers --group system:nodes \
    --username system:node:{{EC2PrivateDNSName}}
```

Since the Ray Cluster creates head and worker pods with different specifications for handling different EC2 families,
we will create two separate nodepools to handle the workload demands.

Here is the first Karpenter `NodePool` that will provision one `Head Pod` on `x86 CPU` instances:

```file
manifests/modules/aiml/chatbot/nodepool/nodepool-x86.yaml
```

Compared to the previous lab, there are more specifications defining the unique constraints
of the `Head Pod`, such as defining an instance family of `r5`, `m5`, and `c5` nodes.

In addition, this secondary `NodePool` will provision `Ray Workers` on `Inf2.48xlarge` instances:

```file
manifests/modules/aiml/chatbot/nodepool/nodepool-inf2.yaml
```

Similarily, there are specifications matching the requirements of the `Ray Workers` that will run
on instances from the `Inf2` family.

Both of these defined nodepools will allow for Karpenter to properly schedule nodes and handle
the workload demands of the Ray Cluster.

Apply the `NodePool` and `EC2NodeClass` manifests for both pools respectively:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/chatbot/nodepool \
  | envsubst | kubectl apply -f-
ec2nodeclass.karpenter.k8s.aws/inferentia-inf2 created
ec2nodeclass.karpenter.k8s.aws/x86-cpu-karpenter created
nodepool.karpenter.sh/inferentia-inf2 created
nodepool.karpenter.sh/x86-cpu-karpenter created
```

Once properly deployed, check for the nodepools:

```bash
$ kubectl get nodepool
NAME                NODECLASS
inferentia-inf2     inferentia-inf2
x86-cpu-karpenter   x86-cpu-karpenter
```

As seen from the above command, both nodepools have been properly provisioned,
allowing for Karpenter to feasibly allocate new nodes into the newly created pools.
