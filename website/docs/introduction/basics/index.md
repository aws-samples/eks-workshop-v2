---
title: Kubernetes Basics
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Learn fundamental Kubernetes concepts including basics, Helm, and Kustomize."
---
# Kubernetes Concepts
Before diving into hands-on labs, it's essential to understand how Kubernetes works and the tools we'll use throughout this workshop. This section covers the architecture, core concepts, and deployment tools that will help you successfully navigate the EKS workshop.

:::info
If you are already familiar with Kubernetes concepts, you can skip this section.
:::

## Kubernetes Architecture Overview

Kubernetes follows a **master-worker architecture** where the control plane manages the cluster and worker nodes run your applications.

### Control Plane Components
The control plane makes global decisions about the cluster and detects/responds to cluster events:

- **API Server** - The front-end for the Kubernetes control plane, exposing the Kubernetes API
- **etcd** - Consistent and highly-available key-value store for all cluster data
- **Scheduler** - Assigns pods to nodes based on resource requirements and constraints
- **Controller Manager** - Runs controller processes that regulate the state of the cluster

### Worker Node Components
Each worker node runs the components necessary to support pods:

- **kubelet** - Agent that communicates with the control plane and manages pods
- **Container Runtime** - Software responsible for running containers (like containerd)
- **kube-proxy** - Network proxy that maintains network rules for pod communication

## Amazon EKS Architecture

Amazon Elastic Kubernetes Service (EKS) provides a fully managed Kubernetes service that eliminates the complexity of operating Kubernetes clusters. With EKS, you can:
* Deploy applications faster with less operational overhead
* Scale seamlessly to meet changing workload demands
* Improve security through AWS integration and automated updates
* Choose between standard EKS or fully automated EKS Auto Mode

In Amazon EKS:
- **AWS manages the control plane** - API server, etcd, scheduler, and controllers run in AWS-managed infrastructure
- **You manage worker nodes** - EC2 instances, Fargate, or hybrid nodes that run your applications
- **Integrated AWS services** - Load balancers, storage, networking, and security services work seamlessly

![](https://docs.aws.amazon.com/images/eks/latest/userguide/images/whatis.png)