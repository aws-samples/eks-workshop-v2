---
title: "Advance Troubleshooting"
sidebar_position: 23
---

In this section, we will use Amazon Q CLI and the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to troubleshoot a complex issue in the EKS cluster, which is more difficult to figure out without decent knowledge of Kubernetes, EKS and AWS cloud platform.

:::caution
You should have Amazon Q CLI with Amazon EKS MCP server configured in your environment for this lab. If that is not the case, please complete [Amazon Q CLI Setup](q-cli-setup.md) lab before you proceed for this lab.
:::

The first step in this process is to re-configure the carts service to use a DynamoDB table that has already been created for us. The application loads most of its configurations from a ConfigMap. Let's take look at it:

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

The following kustomization overwrites the ConfigMap removing the DynamoDB endpoint configuration. It tells the SDK to use the real DynamoDB service instead of our test Pod. We've also configured the DynamoDB table name that's already been created for us. The table name is being pulled from the environment variable `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`.


```kustomization
modules/aiml/q-cli/troubleshoot/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's check the value of `CARTS_DYNAMODB_TABLENAME` then run Kustomize to use the real DynamoDB service:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/dynamo \
  | envsubst | kubectl apply -f-
```

This will overwrite our ConfigMap with new values:

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

Now, we need to recycle all the carts pods to pick up our new ConfigMap contents:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

It looks like our change failed to deploy properly. We can confirm this by looking at the Pods:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

What's gone wrong? Let's ask Q CLI.

Run the following command to start a new Q CLI session.

```bash
$ q chat
```

Ask the following question to Q CLI to troubleshoot this issue.

```text
I have a pod in my eks-workshop cluster that is showing CrashLoopBackOff status. Please troubleshoot the issue and tell me how to solve it.
```

Q CLI would ask you a few permissions to execute different commands to list existing pods, their events, their logs, and their permissions to understand the situation. Once Q CLI gets all required information, it should be able to provide an accurate root cause analysis for the pod being in the pending state and also would offer a solution. 

You may follow the suggestion offered by Q CLI to solve this issue. In ideal scenario, the problem should be fixed and the pod in `CrashLoopBackOff` status should be replaced by a healthy one. At the end, Q CLI would present you the final status summary of the steps it took as shown in the following screenshot. Isn't that amazing?

![q-cli-eks-carts-troubleshooting](./assets/q-cli-response-4.jpg)

The actual response you may get from Q CLI could be a little different. Once you are done, enter the following command to exit Q CLI session.

```text
/quit
```

Let's verify the status of Carts pods in the cluster.

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

As expected, there should be no pod in with status `CrashLoopBackOff` status. This concludes the introduction to Amazon Q CLI. Hope you could appreciate the power of this tool along with the MCP server for EKS.
