---
title: "Accessing AWS APIs securely from workloads"
sidebar_position: 50
description: "Manage AWS credentials for your applications running on Amazon Elastic Kubernetes Service with EKS Pod Identity."
---

:::tip What's been set up for you
Your Amazon EKS Auto Mode cluster includes:

- An Amazon DynamoDB table for the carts service
- An IAM role configured for the carts workload to access DynamoDB

:::

Applications in a Pod's containers can use a supported AWS SDK or the AWS CLI to make API requests to AWS services using AWS Identity and Access Management (IAM) permissions. For example, applications may need to upload files to an S3 bucket or query a DynamoDB table, and in order to do so, they must sign their AWS API requests with AWS credentials. [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) provide the ability to manage credentials for your applications, similar to the way that Amazon EC2 Instance Profiles provide credentials to instances. Instead of creating and distributing your AWS credentials to the containers or using the Amazon EC2 instance's role, you can associate an IAM role with a Kubernetes Service Account and configure your Pods to use it. Check out EKS documentation [here](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html) for the exact list of SDK versions supported.

In this module, we'll reconfigure one of the sample application components to leverage the AWS API and provide it with the appropriate privileges.
