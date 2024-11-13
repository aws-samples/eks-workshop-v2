---
title: "Chaos Engineering with EKS"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: Stimulating various failure scenarios to check Amazon EKS cluster resiliency."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=30
$ prepare-environment observability/resiliency
```

This will make the following changes to your lab environment:

- Create the ingress load balancer
- Create RBAC and Rolebindings
- Install AWS Load Balancer controller
- Create an IAM role for AWS Fault Injection Simulator (FIS)

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/.workshop/terraform).
:::

## What is Resiliency?

Resiliency in cloud computing refers to a system's ability to maintain acceptable performance levels in the face of faults and challenges to normal operation. It encompasses:

1. **Fault Tolerance**: The ability to continue operating properly in the event of the failure of some of its components.
2. **Self-Healing**: The capability to detect and recover from failures automatically.
3. **Scalability**: The ability to handle increased load by adding resources.
4. **Disaster Recovery**: The process of preparing for and recovering from potential disasters.

## Why is Resiliency Important in EKS?

Amazon EKS provides a managed Kubernetes platform, but it's still crucial to design and implement resilient architectures. Here's why:

1. **High Availability**: Ensure your applications remain accessible even during partial system failures.
2. **Data Integrity**: Prevent data loss and maintain consistency during unexpected events.
3. **User Experience**: Minimize downtime and performance degradation to maintain user satisfaction.
4. **Cost Efficiency**: Avoid over-provisioning by building systems that can handle variable loads and partial failures.
5. **Compliance**: Meet regulatory requirements for uptime and data protection in various industries.

## Lab Overview and Resiliency Scenarios

In this lab, we'll explore various high availability scenarios and test the resilience of your EKS environment. Through a series of experiments, you'll gain hands-on experience in handling different types of failures and understanding how your Kubernetes cluster responds to these challenges.

The simulate and respond to:

1. **Pod Failures**: Using ChaosMesh to test your application's resilience to individual pod failures.
2. **Node Failures**: Manually simulating a node failure to observe Kubernetes' self-healing capabilities.

   - Without AWS Fault Injection Simulator: Manually simulating a node failure to observe Kubernetes' self-healing capabilities.
   - With AWS Fault Injection Simulator: Leveraging AWS Fault Injection Simulator for partial and complete node failure scenarios.

3. **Availability Zone Failure**: Simulating the loss of an entire AZ to validate your multi-AZ deployment strategy.

## What You'll Learn

By the end of this chapter, you'll be able to:

- Use AWS Fault Injection Simulator (FIS) to simulate and learn from controlled failure scenarios
- Understand how Kubernetes handles different types of failures (pod, node, and availability zone)
- Observe the self-healing capabilities of Kubernetes in action
- Gain practical experience in chaos engineering for EKS environments

These experiments will help you understand:

- How Kubernetes handles different types of failures
- The importance of proper resource allocation and pod distribution
- The effectiveness of your monitoring and alerting systems
- How to improve your application's fault tolerance and recovery strategies

## Tools and Technologies

Throughout this chapter, we'll be using:

- AWS Fault Injection Simulator (FIS) for controlled chaos engineering
- Chaos Mesh for Kubernetes-native chaos testing
- AWS CloudWatch Synthetics for creating and monitoring a canary
- Kubernetes native features for observing pod and node behavior during failures

## Importance of Chaos Engineering

Chaos engineering is the practice of intentionally introducing controlled failures to identify weaknesses in your system. By proactively testing your system's resilience, you can:

1. Uncover hidden issues before they affect users
2. Build confidence in your system's ability to withstand turbulent conditions
3. Improve your incident response procedures
4. Foster a culture of resilience within your organization

By the end of this lab, you'll have a comprehensive understanding of your EKS environment's high availability capabilities and areas for potential improvement.

:::info
For more information on AWS Resiliency features in greater depth, we recommend checking out:

- [Ingress Load Balancer](/docs/fundamentals/exposing/ingress/)
- [Integrating with Kubernetes RBAC](/docs/security/cluster-access-management/kubernetes-rbac)
- [AWS Fault Injection Simulator](https://aws.amazon.com/fis/)
- [Operating resilient workloads on Amazon EKS](https://aws.amazon.com/blogs/containers/operating-resilient-workloads-on-amazon-eks/)

:::
