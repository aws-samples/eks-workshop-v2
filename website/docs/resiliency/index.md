---
title: "Resiliency"
sidebar_position: 11
weight: 10
---

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
4. **Cost Efficiency**: Avoid overprovisioning by building systems that can handle variable loads and partial failures.
5. **Compliance**: Meet regulatory requirements for uptime and data protection in various industries.

## Resiliency Scenarios Covered in this Chapter

We'll explore several scenarios to show resiliency by by simulating and responding to:

1. Pod Failures
2. Node Failures
3. Availability Zone Failures

## What You'll Learn

By the end of this chapter, you'll be able to:

- Use AWS Fault Injection Simulator (FIS) to simulate and learn from controlled failure scenarios
- Understand how Kubernetes handles different types of failures (pod, node, and availability zone)
- Observe the self-healing capabilities of Kubernetes in action
- Gain practical experience in chaos engineering for EKS environments

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

:::info
For more information on AWS Resiliency features in greater depth, we recommend checking out [Operating resilient workloads on Amazon EKS](https://aws.amazon.com/blogs/containers/operating-resilient-workloads-on-amazon-eks/)
:::
