---
title: "Inference with AWS Inferentia"
sidebar_position: 10
sidebar_custom_props: { "module": true }
---

[AWS Inferentia](https://aws.amazon.com/machine-learning/inferentia/?nc1=h_ls) is the purpose-built accelerator designed to accelerate deep learning workloads.

Inferentia has processing cores called Neuron Cores, which have high-speed access to models stored in on-chip memory.

You can easily use the accelerator on EKS. The Neuron device plugin exposes Neuron cores and devices to Kubernetes as a resource. When your workloads require Neuron cores, the Kubernetes scheduler can assign the Inferentia node to the workloads. You can even provision the node automatically using Karpenter.

This lab provides a tutorial on how to use Inferentia to accelerate deep learning inference workloads on EKS.
In this lab we will:

1. Compile a ResNet-50 pre-trained model for use with AWS Inferentia
2. Upload this model to an S3 Bucket for later use
3. Create a Karpenter Provisioner to provision Inferentia EC2 instances
4. Launch an inference Pod that uses our previous model to run our inference against

Let's get started.
