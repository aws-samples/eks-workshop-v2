---
title: Kubernetes Fundamentals
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Learn fundamental Kubernetes concepts, kubectl CLI, and package management tools."
---

# Kubernetes Fundamentals

Kubernetes is the industry-standard platform for running containerized applications at scale. It automates deployment, scaling, and operations, letting you focus on your applications instead of infrastructure. In this lab, we’ll cover the core concepts of Kubernetes—pods, deployments, services, and more—so you can confidently build and manage cloud-native applications on Amazon EKS.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics
```

:::

You'll be learning the following fundamental concepts in this lab:
- **[Architecture](./architecture)** - Understand how Kubernetes and Amazon EKS work under the hood
- **[Cluster Access](./access)** - Configure access and interact with clusters using kubectl and kubeconfig
- **[Namespaces](./namespaces)** - Organize and isolate resources
- **[Pods](./pods)** - The smallest deployable units in Kubernetes
- **[Workload Management](./workload-management)** - Deployments, StatefulSets, DaemonSets, and Jobs
- **[Services](./services)** - Enable network access and service discovery
- **[Configuration](./configuration)** - ConfigMaps and Secrets for application settings
- **[Package Management](./package-management)** - Kustomize and Helm for managing application