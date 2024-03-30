---
title: "Inference with AWS Inferentia"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Inferentia to accelerate deep learning inference workloads on Amazon Elastic Kubernetes Service."
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/inferentia
```

This will make the following changes to your lab environment:

- Installs Karpenter in the Amazon EKS cluster
- Creates an S3 Bucket to store results
- Creates an IAM Role for the Pods to use
- Installs the [AWS Neuron](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/dlc-then-eks-devflow.html) device plugin

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/inferentia/.workshop/terraform).

:::

[AWS Inferentia](https://aws.amazon.com/machine-learning/inferentia/?nc1=h_ls) is the purpose-built accelerator designed to accelerate deep learning workloads.

Inferentia has processing cores called Neuron Cores, which have high-speed access to models stored in on-chip memory.

You can easily use the accelerator on EKS. The Neuron device plugin exposes Neuron cores and devices to Kubernetes as a resource. When your workloads require Neuron cores, the Kubernetes scheduler can assign the Inferentia node to the workloads. You can even provision the node automatically using Karpenter.

This lab provides a tutorial on how to use Inferentia to accelerate deep learning inference workloads on EKS.
In this lab we will:

1. Compile a ResNet-50 pre-trained model for use with AWS Inferentia
2. Upload this model to an S3 Bucket for later use
3. Create a Karpenter NodePool to provision Inferentia EC2 instances
4. Launch an inference Pod that uses our previous model to run our inference against

Let's get started.
