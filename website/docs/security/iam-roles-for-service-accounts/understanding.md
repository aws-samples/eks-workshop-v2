---
title: "Understanding Pod IAM"
sidebar_position: 30
---

The first place to look for the issue is the logs of the `carts` service:

```bash
$ kubectl logs -n carts deployment/carts
```

This will return a lot of logs, so lets filter it to get a succinct view of the problem:

```bash
$ kubectl -n carts logs deployment/carts \
  | grep DynamoDbException
2024-01-09T18:54:10.818Z ERROR 1 --- ${sys:LOGGED_APPLICATION_NAME}[nio-8080-exec-1] o.a.c.c.C.[.[.[.[dispatcherServlet]      : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: software.amazon.awssdk.services.dynamodb.model.DynamoDbException: User: arn:aws:sts::123456789012:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-vniVa7QtGHXO/i-075976199b049a358 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:123456789012:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: QEQBV8R44MI1DSRQFGIAAAOS8FVV4KQNSO5AEMVJF66Q9ASUAAJG)] with root cause
software.amazon.awssdk.services.dynamodb.model.DynamoDbException: User: arn:aws:sts::123456789012:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-vniVa7QtGHXO/i-075976199b049a358 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:123456789012:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: QEQBV8R44MI1DSRQFGIAAAOS8FVV4KQNSO5AEMVJF66Q9ASUAAJG)
```

Our application is generating an `AccessDeniedException` which indicates that the IAM Role our Pod is using to access DynamoDB does not have the required permissions. This is happening because our Pod is by default using the IAM Role assigned to the EC2 worker node on which its running, which does not have an IAM Policy that allows access to DynamoDB. 

One way we could solve this is to expand the IAM permissions of our EC2 worker nodes, but this would allow any Pod that runs on them to access our DynamoDB table which is not a good practice, and also not secure. Instead we'll using IAM Roles for Service Accounts (IRSA) to specifically allow the Pods in our `carts` service access.
