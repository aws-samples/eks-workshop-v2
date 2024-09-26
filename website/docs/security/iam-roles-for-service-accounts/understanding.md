---
title: "Understanding Pod IAM"
sidebar_position: 23
---

The first place to look for the issue is the logs of the `carts` service:

```bash hook=pod-logs
$ LATEST_POD=$(kubectl get pods -n carts --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
$ kubectl logs -n carts -p $LATEST_POD
[...]
***************************
APPLICATION FAILED TO START
***************************

Description:

An error occurred when accessing Amazon DynamoDB:

User: arn:aws:sts::1234567890:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-rjjGEigUX8KZ/i-01f378b057326852a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: PUIFHHTQ7SNQVERCRJ6VHT8MBBVV4KQNSO5AEMVJF66Q9ASUAAJG)

Action:

Check that the DynamoDB table has been created and your IAM credentials are configured with the appropriate access.
```

The application is generating an error which indicates that the IAM role our Pod is using to access DynamoDB does not have the required permissions. This is happening because by default, if no IAM roles or policies are linked to our Pod, it use the IAM role linked to the instance profile assigned to the EC2 instance on which its running, in this case this role does not have an IAM policy that allows access to DynamoDB.

One way we could solve this is to expand the IAM permissions of our EC2 worker nodes, but this would allow any Pod that runs on them to access our DynamoDB table, but this does not reflect security best practices. Instead we'll using IAM Roles for Service Accounts (IRSA) to specifically allow the Pods in our `carts` service access.
