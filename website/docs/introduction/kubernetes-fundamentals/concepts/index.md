---
title: Concepts
sidebar_position: 10
---

# Kubernetes Concepts

Before diving into hands-on exercises, let's understand the core concepts and architecture of Kubernetes. This foundation will make everything else much clearer.

## What is Kubernetes?

Kubernetes is a container orchestration platform that automates the deployment, scaling, and management of containerized applications. Think of it as an operating system for your cluster of machines.

## Core Architecture

Kubernetes follows a **declarative** model - you describe what you want (the desired state), and Kubernetes works to make it happen.

### Control Plane
The control plane manages the cluster and makes decisions about scheduling, scaling, and maintaining your applications:

- **API Server** - The front door to Kubernetes, handles all requests
- **etcd** - Distributed database storing cluster state
- **Scheduler** - Decides which nodes should run your applications
- **Controller Manager** - Ensures desired state matches actual state

### Worker Nodes
Worker nodes run your applications:

- **kubelet** - Agent that communicates with the control plane
- **Container Runtime** - Runs containers (like Docker or containerd)
- **kube-proxy** - Handles network routing

## Essential Resources

### Pods
- The smallest deployable unit in Kubernetes
- Usually contains one container (but can have more)
- Containers in a Pod share network and storage
- Pods are ephemeral - they come and go

### Deployments
- Manages a set of identical Pods
- Handles scaling, rolling updates, and rollbacks
- Ensures desired number of Pods are always running
- Most common way to run stateless applications

### Services
- Provides stable network endpoint for Pods
- Load balances traffic across multiple Pods
- Enables service discovery within the cluster
- Types: ClusterIP (internal), NodePort (external), LoadBalancer (cloud)

### ConfigMaps and Secrets
- **ConfigMaps** - Store non-sensitive configuration data
- **Secrets** - Store sensitive data like passwords and API keys
- Both can be consumed by Pods as environment variables or files

## Namespaces

Namespaces provide logical separation within a cluster:
- Organize resources by team, environment, or application
- Provide scope for names (same name can exist in different namespaces)
- Enable resource quotas and access controls

## Labels and Selectors

Labels are key-value pairs attached to resources:
- Used to organize and select resources
- Services use selectors to find Pods
- Essential for Kubernetes' loose coupling model

## The Kubernetes API

Everything in Kubernetes is an API object:
- Resources are defined in YAML or JSON
- `kubectl` is a client for the Kubernetes API
- You can interact with the API directly or through tools

## Example: How It All Works Together

Let's trace through a simple example:

1. **You create a Deployment** - Describes desired state (3 replicas of nginx)
2. **API Server stores it** - Deployment definition saved to etcd
3. **Controller notices** - Deployment controller sees new Deployment
4. **Pods are created** - Controller creates 3 Pod definitions
5. **Scheduler assigns nodes** - Decides which nodes should run each Pod
6. **kubelet starts containers** - Pulls images and starts containers
7. **Service routes traffic** - Load balances requests across the 3 Pods

## Key Principles

### Declarative Configuration
- Describe what you want, not how to get there
- Kubernetes continuously works toward desired state
- Configuration is version-controlled and repeatable

### Immutable Infrastructure
- Don't modify running containers
- Deploy new versions instead of updating in place
- Enables reliable rollbacks and consistent environments

### Loose Coupling
- Components communicate through well-defined APIs
- Services abstract away Pod details
- Applications don't need to know about Kubernetes internals

## Next Steps

Now that you understand the core concepts, let's start with hands-on practice:

1. **[Pods](../pods)** - Create and manage the basic unit of deployment
2. **[Deployments](../deployments)** - Learn application lifecycle management
3. **[Services](../services)** - Enable communication between components
4. **[Configuration](../configuration)** - Manage application settings

Each section will reinforce these concepts through practical exercises.