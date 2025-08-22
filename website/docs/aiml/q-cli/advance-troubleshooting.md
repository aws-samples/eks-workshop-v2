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

```bash
$ q chat
```

Ask Q CLI to help troubleshoot the issue:

```text
I have a pod in my eks-workshop cluster that is showing CrashLoopBackOff status. Troubleshoot the issue and solve it.
```

To address the ask, Q CLI will use different tools from the MCP server. You would see the following high-level steps taken by Q CLI to fulfill the ask as listed in the following Q CLI output snippet.

1. Find the failing pod in the cluster using `list_k8s_resources` tool from EKS MCP server
2. Pull details of a pod using `manage_k8s_resource` from EKS MCP server
3. Retrieve and inspect pod logs using `get_pod_logs` tool from EKS MCP server 
4. Inspecting cluster events using `get_k8s_events` tool from EKS MCP server
5. Run `kubectl` commands using `execute_bash` tool that is by default available with Q CLI
6. Retrying an action with a different approach if required
7. Describe IAM roles and policies in the scope using `get_policies_for_role` tool from EKS MCP server
8. Determine the root cause of the problem using the collected data
9. Take corrective action to solve the problem

```text
> I have a pod in my eks-workshop cluster that is showing CrashLoopBackOff status. Troubleshoot the issue and solve it.

> I'll help you troubleshoot the CrashLoopBackOff issue in your EKS cluster. Let me start by identifying the problematic pod and gathering diagnostic information.


🛠️  Using tool: list_k8s_resources from mcp server awslabseks_mcp_server
 ⋮
 ● Running list_k8s_resources with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "field_selector": "status.phase=Running",
 ⋮      "kind": "Pod"
 ⋮    },
 ⋮    "name": "list_k8s_resources"
 ⋮  }

...
...

> I see all the pods are showing as Running. Let me check for pods that might be in CrashLoopBackOff or other problematic states by removing the status filter:


🛠️  Using tool: list_k8s_resources (trusted) from mcp server awslabseks_mcp_server
 ⋮
 ● Running list_k8s_resources with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod"
 ⋮    },
 ⋮    "name": "list_k8s_resources"
 ⋮  }

...
...

> The list shows all pods but doesn't include their status. Let me get detailed information about a specific pod to see the actual status. I notice there are two carts pods - let me check their detailed status:


🛠️  Using tool: manage_k8s_resource from mcp server awslabseks_mcp_server
 ⋮
 ● Running manage_k8s_resource with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod",
 ⋮      "name": "carts-587b87bc65-5nt2q",
 ⋮      "namespace": "carts",
 ⋮      "operation": "read"
 ⋮    },
 ⋮    "name": "manage_k8s_resource"
 ⋮  }

...
...

Let me get the pod logs to understand why it's crashing:


🛠️  Using tool: get_pod_logs from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_pod_logs with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "namespace": "carts",
 ⋮      "pod_name": "carts-587b87bc65-5nt2q",
 ⋮      "tail_lines": 50
 ⋮    },
 ⋮    "name": "get_pod_logs"
 ⋮  }

...
...

> The logs show the application is starting but cut off. Let me get more recent logs and also check events for this pod:


🛠️  Using tool: get_k8s_events from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_k8s_events with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod",
 ⋮      "name": "carts-587b87bc65-5nt2q",
 ⋮      "namespace": "carts"
 ⋮    },
 ⋮    "name": "get_k8s_events"
 ⋮  }

...
...

> The events show the container is starting but then failing and backing off. Let me get the previous container logs to see the actual error:


🛠️  Using tool: execute_bash
 ⋮
 ● I will run the following shell command:
kubectl logs carts-587b87bc65-5nt2q -n carts --previous --context eks-workshop
 ⋮
 ↳ Purpose: Get previous container logs to see the crash reason


...
...

error: context "eks-workshop" does not exist

...
...

> Let me try without the context parameter:


🛠️  Using tool: execute_bash (trusted)
 ⋮
 ● I will run the following shell command:
kubectl logs carts-587b87bc65-5nt2q -n carts --previous
 ⋮
 ↳ Purpose: Get previous container logs to see the crash reason

...
...

> Perfect! Now I can see the root cause. The application is failing because of a DynamoDB permissions issue. The error shows:

Problem: The pod's service account role arn:aws:sts::26XXXXXXXXX3:assumed-role/eks-workshop-carts-dynamo/eks-eks-worksh-carts-587b-4080844a-5f51-4fa9-ac6b-cbf9f18bb8dd is not authorized to perform dynamodb:Query on the
DynamoDB table eks-workshop-carts.

Let me check the current IAM role permissions for the carts service account:


🛠️  Using tool: get_policies_for_role from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_policies_for_role with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "role_name": "eks-workshop-carts-dynamo"
 ⋮    },
 ⋮    "name": "get_policies_for_role"
 ⋮  }

...
...

> Found the issue! The IAM role has permissions for wrong-table-name but the application is trying to access eks-workshop-carts table. I need to update the policy to grant access to the correct DynamoDB table.

Let me add the correct permissions:


🛠️  Using tool: add_inline_policy from mcp server awslabseks_mcp_server
 ⋮
 ● Running add_inline_policy with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "permissions": {
 ⋮        "Action": [
 ⋮          "dynamodb:Query",
 ⋮          "dynamodb:GetItem",
 ⋮          "dynamodb:PutItem",
 ⋮          "dynamodb:UpdateItem",
 ⋮          "dynamodb:DeleteItem",
 ⋮          "dynamodb:Scan"
 ⋮        ],
 ⋮        "Effect": "Allow",
 ⋮        "Resource": [
 ⋮          "arn:aws:dynamodb:us-west-2:26XXXXXXXXX3:table/eks-workshop-carts",
 ⋮          "arn:aws:dynamodb:us-west-2:26XXXXXXXXX3:table/eks-workshop-carts/index/*"
 ⋮        ]
 ⋮      },
 ⋮      "policy_name": "DynamoDBCartsTableAccess",
 ⋮      "role_name": "eks-workshop-carts-dynamo"
 ⋮    },
 ⋮    "name": "add_inline_policy"
 ⋮  }

...
...

```

Follow the suggestion offered by Q CLI to solve this issue. In ideal scenario, the problem should be fixed. At the end, Q CLI would present you the final status summary of the steps it took as shown in the following screenshot. 

![q-cli-eks-carts-troubleshooting](./assets/q-cli-response-4.jpg)

Once you are done, enter the following command to exit Q CLI session.

```text
/quit
```

Finally, verify that the pods are now running correctly:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

This concludes our introduction to Amazon Q CLI. You've seen how this powerful tool, combined with the MCP server for EKS, can help diagnose and resolve complex issues in your EKS cluster.

