---
title: Getting started
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Learn the basics of running workloads on Amazon Elastic Kubernetes Service."
---

::required-time

Welcome to the first hands-on lab in the EKS workshop. The goal of this exercise is to familiarize ourselves with the fundamental conecepts of Kuberntes and deploy sample application components using `kubectl`, `helm` and `kustomize`.

As we deploy these components, we dive into fundamental concepts to become familiar with Kubernetes concepts - such as Pods, Services, Workload Types, etc.

Let's deploy your first workload to the EKS cluster in your lab environment and explore!

Before we begin we need to run the following command to prepare our IDE environment and EKS cluster:

```bash
$ prepare-environment introduction/getting-started
```

What is this command doing? For this lab it is cloning the EKS Workshop Git repository in to the IDE environment so the Kubernetes manifest files we need are present on the file system.

You'll notice in subsequent labs we'll also run this command, where it will perform two important additional functions:

1. Reset the EKS cluster back to its initial state
2. Install any additional components needed in to the cluster for the upcoming lab exercise