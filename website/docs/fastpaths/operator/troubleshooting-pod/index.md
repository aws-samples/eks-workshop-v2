---
title: "Troubleshooting Pod issues"
sidebar_position: 50
description: "Troubleshoot common pod issues in Amazon EKS clusters"
---

::required-time

In this section, we'll learn how to troubleshoot some of the most common pod issues which prevent the containerized application from running in an Amazon EKS cluster, such as ImagePullBackOff and stuck in ContainerCreating state.

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes:

- An Amazon DynamoDB table for the carts service
- An IAM role configured for the carts workload to access DynamoDB

:::

:::info
The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:

- Create a ECR repo named retail-sample-app-ui.
- Create a EC2 instance and push retail store sample app image in to the ECR repo from the instance using tag 0.4.0
- Create a new deployment named ui-private in default namespace.
- Create a new deployment named ui-new in default namespace
- Install aws-efs-csi-driver addon in the EKS cluster.
- Create a EFS filesystem and mount targets.
- Introduce an issue to the deployment spec, so we can learn how to troubleshoot this type of issue.
- Introduce an issue to the deployment spec, so we can learn how to troubleshoot these types of issues
- Create a deployment named efs-app backed by a persistent volume claim named efs-claim to leverage EFS as persistent volume, in the default namespace.

:::
