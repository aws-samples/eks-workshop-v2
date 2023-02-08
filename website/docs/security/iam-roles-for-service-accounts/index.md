---
title: "IAM Roles for Service Accounts"
sidebar_position: 20
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

Applications in a Pod’s containers can use an AWS SDK or the AWS CLI to make API requests to AWS services using AWS Identity and Access Management (IAM) permissions. For example, applications may need to upload files to an S3 bucket or query a DynamoDB table. To do so applications must sign their AWS API requests with AWS credentials. [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) (IRSA) provide the ability to manage credentials for your applications, similar to the way that IAM Instance Profiles provide credentials to Amazon EC2 instances. Instead of creating and distributing your AWS credentials to the containers or relying on the Amazon EC2 Instance Profile for authorization, you associate an IAM Role with a Kubernetes Service Account and configure your Pods to use that Service Account.

In this chapter we'll re-configure one of the sample application components to leverage an AWS API and provide it with the appropriate authentication.
