---
title: "Understanding Pod IAM"
sidebar_position: 33
---

The first place to look for the issue is the logs of the `carts` service:

```bash
$ kubectl -n carts logs deployment/carts
... ommitted output
```

This will return a lot of logs, so lets filter it to get a succinct view of the problem:

```bash
$ kubectl -n carts logs deployment/carts \
  | grep DynamoDb
User: arn:aws:sts::1234567890:assumed-role/eksctl-eks-workshop-nodegroup-def-NodeInstanceRole-P7qjC7RqXaZr/i-085482f0c0bae4f88 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-east-1:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: SD7IOMHAD7VL31S3M8K80A7EI3VV4KQNSO5AEMVJF66Q9ASUAAJG)
```

The application is generating an error which indicates that the IAM Role our Pod is using to access DynamoDB does not have the required permissions. This is happening because by default, if no IAM Roles or Policies are linked to our Pod, it use the IAM Role linked to the Instance Profile assigned to the EC2 instance on which its running, in this case this Role does not have an IAM Policy that allows access to DynamoDB.

One way we could solve this is to expand the IAM permissions of our EC2 Instance Profile, but this would allow any Pod that runs on them to access our DynamoDB table which is not secure, and not a good practice of granting the principle of least privilege. Instead we'll using EKS Pod Identity to allow specific access required by the `carts` application at Pod level.
