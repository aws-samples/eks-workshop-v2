---
title: "Advanced troubleshooting"
sidebar_position: 23
---

In this section, we will use Amazon Q CLI and the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to troubleshoot a complex issue in the EKS cluster that would be difficult to resolve without knowledge of Kubernetes, EKS, and other AWS services.

First, let's reconfigure the carts service to use a DynamoDB table that has been created for us. The application loads most of its configurations from a ConfigMap. Let's examine the current ConfigMap:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  RETAIL_CART_PERSISTENCE_DYNAMODB_CREATE_TABLE: "true"
  RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: Items
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

We'll use the following kustomization to update the ConfigMap. This removes the DynamoDB endpoint configuration, instructing the SDK to use the real DynamoDB service instead of our test Pod. We've also configured the DynamoDB table name in environment variable `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME` that's already been created for us:

```kustomization
modules/aiml/q-cli/troubleshoot/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's verify the DynamoDB table name and apply the new configuration:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/dynamo \
  | envsubst | kubectl apply -f-
```

Verify the updated ConfigMap:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

Now, let's redeploy the carts deployment to pick up the new ConfigMap contents:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

The deployment appears to have failed. Let's check the Pod status:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

Let's use Amazon Q CLI to investigate this issue. Start a new Q CLI session:

```bash test=false
$ q chat
```

Ask Q CLI to help troubleshoot the issue:

```text
I have a pod in my eks-workshop cluster that is with status CrashLoopBackOff. Troubleshoot the issue and resolve it for me.
```

To address the prompt, Q CLI will use a variety of tools from the MCP server. In addition to the tools seen in the previous example, it may also:

1. Describe IAM roles and policies in the scope using `get_policies_for_role` tool from EKS MCP server
2. Fetch further information related to AWS resources with the `use_aws` tools that is built in to Q CLI
3. Take corrective action to solve the problem

Follow the suggestions offered by Q CLI to solve this issue. In an ideal scenario, the problem should be fixed. At the end, Q CLI will present you a final status summary of the steps it took.

<details>
  <summary>Expand for sample response</summary>

```text
Perfect! The CrashLoopBackOff issue has been successfully resolved. Here's a summary of what I found and fixed:

## Problem Analysis

The pod carts-d49c67c77-k2zvz in the carts namespace was in CrashLoopBackOff state with:
• **Restart count:** 9 restarts
• **Exit code:** 1 (error)
• **Root cause:** DynamoDB permissions issue

## Root Cause

The application logs showed this error:
User: arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-dynamo/eks-eks-worksh-carts-d49c-c1857ccc-86be-4bd6-9c6d-0b90748341b4 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action


The IAM role eks-workshop-carts-dynamo had a policy that granted access to a table named wrong-table-name, but the application was trying to access eks-workshop-carts.

## Solution Applied

1. Identified the correct DynamoDB table: eks-workshop-carts
2. Added proper IAM permissions: Created an inline policy CartsTableAccess with the following permissions:
   • Actions: dynamodb:GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, BatchWriteItem
   • Resources: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts and its indexes
3. Restarted the pod: Deleted the failing pod to allow the deployment to create a new one with the updated permissions

## Result

The new pod carts-d49c67c77-mks7h is now:
• **Status:** Running and Ready
• **Restart count:** 0
• **Application:** Successfully started and connected to DynamoDB
• **Health checks:** Passing (both liveness and readiness probes)

The CrashLoopBackOff issue has been completely resolved, and the carts service is now functioning properly with correct DynamoDB access permissions.
```

</details>

Once you are done, enter the following command to exit Q CLI session.

```text
/quit
```

Finally, verify that the pods are now running correctly:

```bash test=false
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

This concludes our introduction to Amazon Q CLI. You've seen how this powerful tool, combined with the MCP server for EKS, can help diagnose and resolve complex issues in your EKS cluster.
