---
title: "Karpenter Setup"
sidebar_position: 20
---

In this section we will configure Karpenter to allow the creation of Inferentia and Trainium EC2 instances. Karpenter can detect the pending Pods that require an inf2 or trn1 instance. Karpenter will then launch the required instance to schedule the Pod.

:::tip
You can learn more about Karpenter in the [Karpenter module](../../autoscaling/compute/karpenter/index.md) that's provided in this workshop.
:::

Karpenter has been installed in our EKS cluster, and runs as a deployment:

```bash
$ kubectl get deployment -n kube-system
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
...
karpenter   2/2     2            2           11m
```

The only setup that we will need to do is to update our EKS IAM mappings to allow Karpenter nodes to join the cluster:

```bash
$ eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME \
    --region $AWS_REGION --arn $KARPENTER_ARN \
    --group system:bootstrappers --group system:nodes \
    --username system:node:{{EC2PrivateDNSName}}
```

Karpenter requires a `NodePool` to provision nodes. This is the Karpenter `NodePool` that we will create:

::yaml{file="manifests/modules/aiml/inferentia/nodepool/nodepool.yaml" paths="spec.template.spec.requirements.2,spec.template.spec.requirements.2.values"}

1. In this section we assign what instances this NodePool is allowed to provision for us
2. You can see here that we've configured this NodePool to only allow the creation of inf2 and trn1 instances

Apply the `NodePool` and `EC2NodeClass` manifest:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/nodepool \
  | envsubst | kubectl apply -f-
```

Now the NodePool is ready for the creation for our training and inference Pods.
