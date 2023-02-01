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
  | grep AmazonDynamoDBException
2022-08-01 20:46:40.648 ERROR 1 --- [nio-8080-exec-1] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is com.amazonaws.services.dynamodbv2.model.AmazonDynamoDBException: User: arn:aws:sts::1234567890:assumed-role/eks-workshop-managed-ondemand/i-09e2e801deff1197a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: AmazonDynamoDBv2; Status Code: 400; Error Code: AccessDeniedException; Request ID: BDDGUIJ5N8PSEI03F4U15NI727VV4KQNSO5AEMVJF66Q9ASUAAJG; Proxy: null)] with root cause
com.amazonaws.services.dynamodbv2.model.AmazonDynamoDBException: User: arn:aws:sts::1234567890:assumed-role/eks-workshop-managed-ondemand/i-09e2e801deff1197a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: AmazonDynamoDBv2; Status Code: 400; Error Code: AccessDeniedException; Request ID: BDDGUIJ5N8PSEI03F4U15NI727VV4KQNSO5AEMVJF66Q9ASUAAJG; Proxy: null)
```

Our application is generating an `AccessDeniedException` which indicates that the IAM Role our Pod is using to access DynamoDB does not have the required permissions. This is happening because our Pod is by default using the IAM Role assigned to the EC2 worker node on which its running, which does not have an IAM Policy that allows access to DynamoDB. 

One way we could solve this is to expand the IAM permissions of our EC2 worker nodes, but this would allow any Pod that runs on them to access our DynamoDB table which is not a good practice, and also not secure. Instead we'll using IAM Roles for Service Accounts (IRSA) to specifically allow the Pods in our `carts` service access.
