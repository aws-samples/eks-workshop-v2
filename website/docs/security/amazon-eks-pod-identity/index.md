---
title: "Amazon EKS Pod Identity"
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

{{% required-time %}}

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment security/eks-pod-identity
```

This will make the following changes to your lab environment:

- Create an Amazon DynamoDB table
- Create an IAM role for AmazonEKS workloads to access the DynamoDB table
- Install the EKS Managed Addon for EKS Pod Identity Agent 
- Install the AWS Load Balancer Controller in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/pod-identity/.workshop/terraform).

:::

Applications in a Pod’s containers can use a supported AWS SDK or the AWS CLI to make API requests to AWS services using AWS Identity and Access Management (IAM) permissions. For example, applications may need to upload files to an S3 bucket or query a DynamoDB table, and in order to do so, they must sign their AWS API requests with AWS credentials. [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) provide the ability to manage credentials for your applications, similar to the way that Amazon EC2 Instance Profiles provide credentials to instances. Instead of creating and distributing your AWS credentials to the containers or using the Amazon EC2 instance's Role, you can associate an IAM Role with a Kubernetes Service Account and configure your Pods with it. Check out EKS documentation [here](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html) for the exact list of versions supported.

In this chapter we'll re-configure one of the sample application components to leverage the AWS API and provide it with the appropriate privileges.
