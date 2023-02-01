---
title: "Networking"
sidebar_position: 3
chapter: true
weight: 20
---

It's essential to understand Kubernetes networking to operate your cluster and applications efficiently. Pod networking, also called cluster networking, is the center of Kubernetes networking. Kubernetes supports Container Network Interface (CNI) plugins for cluster networking.

EKS uses Amazon VPC to provide networking capabilities to worker nodes and Kubernetes Pods. An EKS cluster consists of two VPCs: an AWS managed VPC that hosts the Kubernetes control plane and a second customer-managed VPC that hosts the Kubernetes worker nodes where containers run, as well as other AWS infrastructure (like load balancers) used by a cluster. All worker nodes need the ability to connect to the managed API server endpoint. This connection allows the worker node to register itself with the Kubernetes control plane and to receive requests to run application pods.

Worker nodes connect to the EKS control plane through the EKS public endpoint or EKS-managed elastic network interfaces (ENIs). The subnets that you pass when you create a cluster influence where EKS places these ENIs. You need to provide a minimum of two subnets in at least two Availability Zones. The route that worker nodes take to connect is determined by whether you have enabled or disabled the private endpoint for your cluster. EKS uses the EKS-managed ENI to communicate with worker nodes.

Amazon EKS officially supports Amazon Virtual Private Cloud (VPC) CNI plugin to implement Kubernetes Pod networking. The VPC CNI provides native integration with AWS VPC and works in underlay mode. In underlay mode, Pods and hosts are located at the same network layer and share the network namespace. The IP address of the Pod is consistent from the cluster and VPC perspective.
