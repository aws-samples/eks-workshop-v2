---
title: "Resiliency"
sidebar_position: 11
weight: 10
---

TODO:

- Add intro information
- Find a lab to input

Other TODO:

- autotesting
- Containers on couch vod (link it here?)

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

## Resiliency Scenarios Covered in this Chapter

We'll explore several scenarios to show resiliency by performing:

1. Pod Failures
2. Node Failures
3. Availability Zone Failures

## What You'll Learn

By the end of this chapter, you'll be able to:

- Use AWS FIS to simulate and learn from controlled failure scenarios
- other info

:::info

<!-- To explore AWS Resiliency features in greater depth, we recommend checking out the [other lab](anotherlab). -->

:::
