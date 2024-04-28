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
$ kubectl -n carts logs deployment/carts | grep -i Exception
2024-02-12T20:20:47.547Z ERROR 1 --- [nio-8080-exec-7] o.a.c.c.C.[.[.[.[dispatcherServlet]      : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: com.amazonaws.services.dynamodbv2.model.AmazonDynamoDBException: User: arn:aws:sts::123456789000:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-Q1p0w2o9e3i8/i-0p1qaz2wsx3edc4rfv is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:123456789000:table/Items/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: AmazonDynamoDBv2; Status Code: 400; Error Code: AccessDeniedException; Request ID: MA54K0UDUOCLJ96UP6PT76VTBBVV4KQNSO5AEMVJF66Q9ASUAAJG; Proxy: null)] with root cause
com.amazonaws.services.dynamodbv2.model.AmazonDynamoDBException: User: arn:aws:sts::123456789000:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-Q1p0w2o9e3i8/i-0p1qaz2wsx3edc4rfv is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:123456789000:table/Items/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: AmazonDynamoDBv2; Status Code: 400; Error Code: AccessDeniedException; Request ID: MA54K0UDUOCLJ96UP6PT76VTBBVV4KQNSO5AEMVJF66Q9ASUAAJG; Proxy: null)
```

The application is generating an `AccessDeniedException` which indicates that the IAM Role our Pod is using to access DynamoDB does not have the required permissions. This is happening because by default, if no IAM Roles or Policies are linked to our Pod, it use the IAM Role linked to the Instance Profile assigned to the EC2 instance on which its running, in this case this Role does not have an IAM Policy that allows access to DynamoDB.

One way we could solve this is to expand the IAM permissions of our EC2 Instance Profile, but this would allow any Pod that runs on them to access our DynamoDB table which is not secure, and not a good practice of granting the principle of least privilege. Instead we'll using EKS Pod Identity to allow specific access required by the `carts` application at Pod level.
