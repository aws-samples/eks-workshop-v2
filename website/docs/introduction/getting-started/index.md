---
title: Getting started
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Deploy and explore a real microservices application on Amazon EKS."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/getting-started
```

:::

Now that you understand the fundamental Kubernetes concepts from [Kubernetes Fundamentals](../kubernetes-fundamentals), let's apply that knowledge to deploy and explore a real microservices application on EKS.

## What you'll learn

In this section, you'll:

- **Understand** the architecture of a microservices application
- **Deploy** a complete application using the concepts you've learned
- **Explore** how Kubernetes resources work together in practice
- **Troubleshoot** and interact with a running application
- **See** real-world applications of Pods, Deployments, Services, and Configuration

## Prerequisites

Before starting this section, you should have completed [Kubernetes Fundamentals](../kubernetes-fundamentals) to understand:
- What Pods, Deployments, and Services are
- How configuration works with ConfigMaps and Secrets
- Basic kubectl commands and troubleshooting

## Learning approach

This section takes a **practical application** approach:

1. **Understand the application** - Learn about the sample retail application
2. **Deploy step by step** - Start with one component, then deploy the full application
3. **Explore what was created** - Use your Kubernetes knowledge to understand the resources
4. **Interact with the application** - See how it works from a user perspective

## The sample application

We'll be working with a retail store application that demonstrates real-world microservices patterns. This application will be used throughout the workshop, so understanding it well will help in later modules.

Let's start by exploring the [Sample Application](./sample-application) architecture and then deploy it step by step.
