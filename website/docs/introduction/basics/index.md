---
title: Kubernetes Basics
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Learn fundamental Kubernetes concepts including architecture, Helm, and Kustomize."
---

# Kubernetes Concepts

Before diving into hands-on labs, it's important to understand **how Kubernetes works** and **the tools you'll use** throughout this workshop. This section introduces the core architecture, key components, and deployment tools that form the foundation of your EKS learning journey.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics
```

:::

## Kubernetes Architecture Overview

Kubernetes follows a **control plane–worker node architecture**, where the **control plane** manages the cluster and **worker nodes** run your workloads.

![Kubernetes Cluster Architecture](https://kubernetes.io/images/docs/kubernetes-cluster-architecture.svg)
*Figure: Simplified Kubernetes cluster architecture.*

### Control Plane Components

The control plane makes global decisions about the cluster and ensures the system’s desired state.

- **API Server** — Acts as the front-end for Kubernetes, exposing the Kubernetes API to users and components.  
- **etcd** — A highly available key-value store that holds all cluster data.  
- **Scheduler** — Assigns Pods to nodes based on resource availability and constraints.  
- **Controller Manager** — Runs background processes (controllers) that maintain cluster health and reconcile actual vs. desired states.

### Worker Node Components

Each node runs the components needed to host and manage Pods.

- **kubelet** — Communicates with the control plane and ensures containers are running as expected.  
- **Container Runtime** — Executes containers (e.g., containerd, CRI-O).  
- **kube-proxy** — Maintains network rules and manages communication between Pods and services.

---

## Amazon EKS Architecture

**Amazon Elastic Kubernetes Service (EKS)** is a managed Kubernetes service that simplifies cluster operations.  
It takes care of control plane management, upgrades, and high availability, so you can focus on your workloads.

With EKS, you can:
- **Deploy applications faster** with less operational overhead  
- **Scale seamlessly** to handle changing workloads  
- **Enhance security** using AWS IAM and managed updates  
- **Choose your compute model** — traditional EC2 nodes or serverless with EKS Auto Mode

### Shared Responsibility Model

In Amazon EKS:
- **AWS manages the control plane** — including the API Server, etcd, scheduler, and controllers.  
- **You manage the worker nodes** — EC2, Fargate, or hybrid options where your applications run.  
- **AWS services integrate natively** — including load balancers, IAM roles, VPC networking, and storage.

![Amazon EKS Architecture](https://docs.aws.amazon.com/images/eks/latest/userguide/images/whatis.png)
*Figure: Amazon EKS architecture and integration with AWS services.*

## Key Points to Remember

Understanding Kubernetes architecture is crucial for effective cluster management and troubleshooting:

### Control Plane vs. Worker Nodes
- **Control plane** components (API Server, etcd, Scheduler, Controller Manager) handle cluster-wide decisions and state management
- **Worker nodes** (kubelet, container runtime, kube-proxy) focus on running and networking your applications
- This separation allows for scalable, resilient cluster operations

### EKS Advantages
- **Reduced operational burden** — AWS manages control plane complexity, patching, and high availability
- **Native AWS integration** — Seamless connectivity with VPC, IAM, Load Balancers, and other AWS services
- **Flexible compute options** — Choose between EC2, Fargate, or Auto Mode based on your workload needs

### Design Principles
- **Declarative configuration** — Define desired state; Kubernetes controllers work to achieve it
- **API-driven** — All interactions go through the Kubernetes API for consistency and auditability
- **Extensible** — Custom resources and controllers allow you to extend Kubernetes functionality

These architectural concepts will be essential as you progress through deploying applications, managing configurations with Helm and Kustomize, and implementing advanced cluster features.
