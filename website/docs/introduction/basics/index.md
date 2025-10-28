---
title: Kubernetes Fundamentals
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Learn fundamental Kubernetes concepts, kubectl CLI, and package management tools."
---

# Kubernetes Fundamentals

This section provides hands-on experience with essential Kubernetes concepts and tools you'll use throughout the EKS workshop. You'll learn to interact with clusters, manage workloads, and deploy applications using industry-standard tools.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics
```

:::

## What You'll Learn

In this section, you'll gain practical experience with the fundamental concepts and tools that power Kubernetes and Amazon EKS. Through hands-on labs, you'll build the skills needed for the rest of the workshop.

### [Architecture](./architecture)
**Start here** - Understand how Kubernetes and Amazon EKS work under the hood, including control plane components, worker nodes, and the shared responsibility model.

### [Interacting with Kubernetes](./interacting)
Learn how to configure access and interact with Kubernetes clusters using kubeconfig and kubectl.

### Core Kubernetes Resources
Explore the fundamental building blocks:
- **[Namespaces](./namespaces)** - Logical resource separation and organization
- **[Pods](./pods)** - The smallest deployable units
- **[Workload Management](./workload-management)** - Deployments, StatefulSets, and Jobs
- **[Services](./services)** - Network access and service discovery  
- **[Configuration](./configuration)** - ConfigMaps and Secrets

### [Package Management](./package-management)
Understand the tools for managing complex Kubernetes applications:
- **Kustomize** - Declarative configuration management
- **Helm** - Package manager and templating engine

This progression takes you from **understanding the architecture** → **learning how to interact** → **exploring core resources** → **managing complex deployments**. These concepts and tools will be essential as you progress through the workshop.