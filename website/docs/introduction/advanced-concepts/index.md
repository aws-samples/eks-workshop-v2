---
title: Advanced concepts
sidebar_custom_props: { "module": true }
sidebar_position: 45
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/advanced-concepts
```

:::

Now that you've mastered the fundamentals and deployed a real application, let's explore advanced Kubernetes concepts that you'll encounter in production environments.

## What you'll learn

This section covers advanced Kubernetes concepts that build upon your foundation:

- **[Workloads](./workloads)** - StatefulSets, DaemonSets, and Jobs for specialized use cases
- **[Nodes](./nodes)** - Advanced scheduling, taints, tolerations, and node management
- **[RBAC](./rbac)** - Role-Based Access Control for security and governance

## Prerequisites

Before starting this section, you should have completed:
- [Kubernetes Fundamentals](../kubernetes-fundamentals) - Core concepts and basic resources
- [Getting Started](../getting-started) - Real application deployment experience

## Learning approach

This section uses the **advanced application** approach:

1. **Learn the concepts** - Understand when and why to use advanced resources
2. **See real examples** - Use components from the retail application where applicable
3. **Practice with purpose** - Each exercise solves a real-world problem
4. **Build production skills** - Focus on patterns you'll use in production

## When to use advanced concepts

### StatefulSets
- Applications that need persistent storage
- Services that require stable network identities
- Databases and other stateful workloads

### DaemonSets
- System-level services that run on every node
- Monitoring agents, log collectors, network plugins
- Security scanners and compliance tools

### Jobs and CronJobs
- Batch processing and data migration
- Scheduled maintenance tasks
- One-time initialization scripts

### Node Management
- Controlling workload placement
- Managing node maintenance
- Handling specialized hardware

### RBAC
- Multi-tenant environments
- Compliance and security requirements
- Principle of least privilege

## Real-world context

The retail application you deployed uses several of these concepts:

- **StatefulSets** - For MySQL, PostgreSQL, and Redis databases
- **Node scheduling** - Could be used to place databases on storage-optimized nodes
- **RBAC** - Essential for production deployments with multiple teams

## Getting started

Begin with [Workloads](./workloads) to understand specialized workload types, then progress through node management and security concepts.

After completing this section, you'll have the knowledge needed for production Kubernetes deployments and can confidently proceed to the [Fundamentals module](/docs/fundamentals) for EKS-specific features.