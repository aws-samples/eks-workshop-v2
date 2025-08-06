---
title: Kubernetes fundamentals
sidebar_custom_props: { "module": true }
sidebar_position: 30
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/kubernetes-fundamentals
```

:::

Welcome to Kubernetes fundamentals! This section provides a solid foundation in core Kubernetes concepts before you deploy real applications. You'll learn about the essential building blocks of Kubernetes through hands-on exercises using simple, focused examples.

## What you'll learn

In this section, you'll master the fundamental concepts that form the foundation of container orchestration:

- **[Concepts](./concepts)** - Core Kubernetes terminology and architecture
- **[Pods](./pods)** - The basic unit of deployment, including health checks and troubleshooting
- **[Deployments](./deployments)** - Managing application lifecycle, scaling, and updates
- **[Services](./services)** - Enabling communication between components
- **[Configuration](./configuration)** - Managing application settings with ConfigMaps and Secrets

## Learning approach

This section uses a **concepts-first** approach:

1. **Understand the theory** - Learn what each Kubernetes resource does and why it exists
2. **Practice with examples** - Create simple, focused examples to reinforce concepts
3. **Build incrementally** - Each section builds upon previous knowledge
4. **Prepare for real-world use** - Gain the foundation needed for the sample application

## Why start here?

Understanding these fundamentals will make the [Getting Started](../getting-started) section much more meaningful. Instead of just following commands, you'll understand:

- What resources you're creating
- Why they're structured the way they are
- How they work together
- How to troubleshoot when things go wrong

## Prerequisites

Before starting this section, ensure you have completed the [Setup](../setup) section to prepare your EKS cluster and development environment.

## Getting started

Begin with [Concepts](./concepts) to understand Kubernetes architecture, then progress through each section in order. Each section includes both explanations and hands-on exercises.

After completing this section, you'll be ready to deploy and understand a real microservices application in [Getting Started](../getting-started).