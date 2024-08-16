---
title: "High Availability"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Prepare your EKS environment to handle high availability scenarios effectively."
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ /manifests/modules/resiliency/.workshop/cleanup.sh
$ prepare-environment resiliency
```

This will make the following changes to your lab environment:

- Create the ingress load balancer
- Create RBAC and Rolebindings
- Install AWS Load Balancer controller
- Install ChaosMesh
- Create an IAM role for AWS Fault Injection Simulator (FIS)

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/.workshop/terraform).
:::

## Lab Overview

In this lab, we'll explore various high availability scenarios and test the resilience of your EKS environment. Through a series of experiments, you'll gain hands-on experience in handling different types of failures and understanding how your Kubernetes cluster responds to these challenges.

The experiments we'll conduct include:

1. Pod Failure Simulation: Using ChaosMesh to test your application's resilience to individual pod failures.
2. Node Failure without FIS: Manually simulating a node failure to observe Kubernetes' self-healing capabilities.
3. Partial Node Failure with FIS: Leveraging AWS Fault Injection Simulator to create a more controlled node failure scenario.
4. Complete Node Failure with FIS: Testing your cluster's response to a catastrophic failure of all nodes.
5. Availability Zone Failure: Simulating the loss of an entire AZ to validate your multi-AZ deployment strategy.

These experiments will help you understand:

- How Kubernetes handles different types of failures
- The importance of proper resource allocation and pod distribution
- The effectiveness of your monitoring and alerting systems
- How to improve your application's fault tolerance and recovery strategies

By the end of this lab, you'll have a comprehensive understanding of your EKS environment's high availability capabilities and areas for potential improvement.

:::info
For more information on the components used in this lab, check out:

- [Ingress Load Balancer](/docs/fundamentals/exposing/ingress/)
- [Integrating with Kubernetes RBAC](/docs/security/cluster-access-management/kubernetes-rbac)
- [Chaos Mesh](https://chaos-mesh.org/)
- [AWS Fault Injection Simulator](https://aws.amazon.com/fis/)
  :::
