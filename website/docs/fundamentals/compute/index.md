---
title: "Compute"
sidebar_position: 40
---

[Compute on EKS](https://docs.aws.amazon.com/eks/latest/userguide/eks-compute.html) provides multiple options for running your containerized workloads, each designed for different use cases and operational requirements.

Before we dive into the implementation, below is a summary of the compute options we'll explore and integrate with EKS:

- [Amazon EKS Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html): Automate the provisioning and lifecycle management of EC2 nodes for your EKS cluster. Managed node groups simplify operational activities such as rolling updates for new AMIs or Kubernetes version deployments, while providing full control over the underlying EC2 instances.

- [Karpenter](https://karpenter.sh/): An open-source Kubernetes cluster autoscaler that automatically provisions right-sized compute resources in response to changing application load. Karpenter improves application availability and cluster efficiency by rapidly launching and terminating nodes as needed.


- [AWS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html): A serverless compute engine for containers that eliminates the need to provision, configure, or scale groups of virtual machines. With Fargate, you focus on designing and building your applications instead of managing the infrastructure that runs them.


It's also important to understand key concepts about [Kubernetes compute resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/):

- [Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/): Worker machines in Kubernetes that run your containerized applications. Each node contains the services necessary to run Pods and is managed by the control plane.
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/): The smallest deployable units in Kubernetes, consisting of one or more containers that share storage and network resources.
- [Resource Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/): Mechanisms to specify how much CPU and memory your containers need (requests) and the maximum they can use (limits).
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity): Rules that constrain which nodes your Pods can be scheduled on based on node labels.
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/): Mechanisms that work together to ensure Pods are not scheduled onto inappropriate nodes.

Additional compute considerations covered in this section:

- **Graviton Processors**: Learn how to leverage AWS Graviton-based EC2 instances for better price performance in your EKS workloads.
- **Spot Instances**: Understand how to use Amazon EC2 Spot Instances to reduce compute costs while maintaining application availability.
- **Cluster Autoscaler**: Explore the traditional cluster autoscaling approach and compare it with modern alternatives like Karpenter.
- **Overprovisioning**: Implement strategies to reduce Pod scheduling latency by maintaining spare capacity in your cluster.

In the following labs, we'll start with managed node groups to understand the fundamentals of EKS compute, then explore Karpenter for advanced autoscaling capabilities, and finally examine Fargate for serverless container execution.
