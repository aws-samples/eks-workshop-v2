---
title: Getting started
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

Welcome to the first hands-on lab in the EKS workshop. The goal of this exercise is to familiarize ourselves with the sample application we'll use for many of the coming lab exercises and in doing so touch on some basic concepts related to deploying workloads to EKS. We'll explore the architecture of the application and deploy out the components to our EKS cluster.

Let's deploy your first workload to the EKS cluster in your lab environment and explore!

Before we begin we need to run the following command to prepare our Cloud9 environment and EKS cluster:

```bash
$ prepare-environment introduction/getting-started
```

What is this command doing? For this lab it is cloning the EKS Workshop Git repository on to the Cloud9 environment so the Kubernetes manifest files we need are present on the file system. 

You'll notice in subsequent labs we'll also run this command, where it will perform two important additional functions:

1. Reset the EKS cluster back to its initial state
2. Install any additional components needed in to the cluster for the upcoming lab exercise