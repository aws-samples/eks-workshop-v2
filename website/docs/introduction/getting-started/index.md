---
title: Getting Started
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Learn the basics of running workloads on Amazon Elastic Kubernetes Service."
---

::required-time

Welcome to the first hands-on lab in the EKS workshop. The goal of this exercise is to prepare the IDE with necessary configurations and explore the structure.

Before we begin we need to run the following command to prepare our IDE environment and EKS cluster:

:::tip Prepare your environment for this section:

```bash
$ prepare-environment introduction/getting-started
```
This command will clone the EKS workshop Git repository into the IDE environment.
:::

The `prepare-environment` command is a crucial tool that sets up your lab environment for each workshop module. Here's what it does behind the scenes:

- **Repository Setup**: Downloads the latest EKS Workshop content from GitHub to `/eks-workshop/repository` and links Kubernetes manifests to `~/environment/eks-workshop`
- **Cluster Reset & Cleanup**: Resets the sample retail application to its base state. Removes any leftover resources from previouse labs and restores EKS managed node groups to initial size (3 nodes).
- **Lab-Specific Infrastructure**: Ensure the target module is ready to use by creating any extra AWS resources using Terraform, deploying the required Kubernetes manifests, configuring environment variables, and installing necessary add-ons or components.

## Repository Structure Overview

After running `prepare-environment`, you'll have access to the workshop materials in your IDE. Here's how the repository is organized:

#### Key Directories

**`~/environment/eks-workshop/`** - Your main working directory containing:

- **`base-application/`** - The core retail store application manifests
  - `ui/` - Frontend web interface
  - `catalog/` - Product catalog service
  - `carts/` - Shopping cart service  
  - `checkout/` - Order checkout service
  - `orders/` - Order management service

- **`modules/`** - Lab-specific resources organized by learning module
  - `introduction/` - Getting started and basic concepts
  - `fundamentals/` - Core Kubernetes and EKS concepts
  - `networking/` - VPC CNI, load balancing, ingress
  - `security/` - Pod security, RBAC, encryption
  - `observability/` - Monitoring, logging, tracing
  - `autoscaling/` - HPA, VPA, Cluster Autoscaler, Karpenter
  - And more...

#### Lab Structure Pattern

Each lab follows a consistent structure:
```
modules/<module>/<lab>/
├── .workshop/
│   ├── terraform/          # Lab-specific AWS infrastructure
│   ├── cleanup.sh         # Reset script for this lab
│   └── manifests/         # Additional Kubernetes resources
└── <kubernetes-files>     # Main lab Kubernetes manifests
```

This modular approach allows you to:
- Jump between labs in any order
- Have consistent, isolated environments for each exercise
- Easily reset and clean up between labs

:::tip Congratulations!

You've successfully prepared your EKS workshop environment! You cluster is ready and the repository structure is set up for hands-on learning.

:::

### What's Next?

We can deploy the application in several ways, and we'll be using `Kustomize` throughout this workshop. However, you need a good understanding of Kubernetes basics for the best learning experience. 

The following optional labs will set you up with the necessary knowledge by deploying and exploring the sample application:

**[Kubernetes Basics](./concepts/kubernetes-basics)** - Deploy the retail store application step-by-step using core Kubernetes resources. Learn how pods, deployments, and services work together by creating them yourself.

**[Kustomize](./concepts/kustomize)** - Use Kustomize to deploy and customize the application for different environments. Learn how to manage configuration variations without duplicating YAML files.

**[Helm](./concepts/helm)** - Deploy the application using Helm charts. Understand how Helm simplifies complex deployments and enables reusable, templated configurations.
