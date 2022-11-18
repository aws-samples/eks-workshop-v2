---
title: "Introduction to Bottlerocket"
sidebar_position: 50
---

[Bottlerocket](https://aws.amazon.com/bottlerocket/) is a Linux-based open-source operating system that is purpose-built by Amazon Web Services for running containers. Bottlerocket includes only the essential software required to run containers, and ensures that the underlying software is always secure. With Bottlerocket, customers can reduce maintenance overhead and automate their workflows by applying configuration settings consistently as nodes are upgraded or replaced. Bottlerocket is now generally available at no cost as an Amazon Machine Image (AMI) for Amazon Elastic Compute Cloud (EC2).

In this Chapter, we will deploy three Bottlerocket-based nodes and deploy the carts pod on one of the nodes. Please look into the prerequisites before moving into the next section:

## Amazon provides official AMIs in the following AWS regions:

```
| Region Name               |            Region     |
| -------------             |         ------------- |
| Africa (Cape Town)        |            ap-east-1  |
| Asia Pacific (Hong Kong)  |            ap-east-1  |
| Asia Pacific (Tokyo)      |       ap-northeast-1  |
| Asia Pacific (Seoul)      |       ap-northeast-2  |
| Asia Pacific (Osaka)      |       ap-northeast-3  |
| Asia Pacific (Mumbai)     |           ap-south-1  |
| Asia Pacific (Singapore)  |       ap-southeast-1  |
| Asia Pacific (Sydney)     |       ap-southeast-2  |
| Canada (Central)          |         ca-central-1  |
| Europe (Frankfurt)        |         eu-central-1  |
| Europe (Stockholm)        |           eu-north-1  |
| Europe (Milan)            |           eu-south-1  |
| Europe (Ireland)          |            eu-west-1  |
| Europe (London)           |            eu-west-2  |
| Europe (Paris)            |            eu-west-3  |
| Middle East (Bahrain)     |           me-south-1  |
| South America (São Paulo) |            sa-east-1  |
| US East (N. Virginia)     |            us-east-1  |
| US East (Ohio)            |            us-east-2  |
| US West (N. California)   |            us-west-1  |
| US West (Oregon)          |            us-west-2  |
```

!!! **Note** : The AMI ID will vary, depending upon on the AWS region. To verify the AMI ID, you can use the below Systems Manager command, changing region and cluster version as per your environment. Please do not continue the lab unless you can use one of the above regions.

```bash 
$ aws ssm get-parameter --region us-east-1 --name "/aws/service/bottlerocket/aws-k8s-1.23/x86_64/latest/image_id" --query Parameter.Value --output text
```


