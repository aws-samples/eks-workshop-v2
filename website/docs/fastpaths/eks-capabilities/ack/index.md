---
title: "Provision AWS resources with ACK"
sidebar_position: 10
---

::required-time{estimatedLabExecutionTimeMinutes="10"}

:::tip What's been set up for you

- The **ACK EKS-managed capability** is enabled on the cluster, with the DynamoDB controller selected. The capability assumes an IAM Capability Role scoped to a single DynamoDB table named `${EKS_CLUSTER_AUTO_NAME}-carts-fastpath`.
- An **IAM role** for the `carts` ServiceAccount is pre-provisioned (`${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`) so the application Pod can read and write the table via [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).
- The base retail application is running with `carts` pointing at the in-cluster `carts-dynamodb` Pod.

:::

By default, the **carts** component in the sample application uses a [DynamoDB local](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) instance running as a Pod called `carts-dynamodb`. In this lab we'll provision a real Amazon DynamoDB table using a Kubernetes manifest, then point the `carts` Deployment at the cloud-managed table.

Unlike the [self-managed ACK lab](/docs/automation/controlplanes/ack), there's no `helm install ack-dynamodb-controller` step here. The DynamoDB controller is delivered by the **ACK EKS capability** — a fully managed control-plane component that lives in AWS-owned infrastructure and assumes an IAM Capability Role to act on AWS resources for the cluster.

Throughout this lab, we will:

1. Verify the ACK capability is `ACTIVE` and the DynamoDB CRDs are present in the cluster.
2. Provision a DynamoDB table by applying a Kubernetes `Table` custom resource.
3. Migrate the `carts` Deployment from the in-cluster DynamoDB Pod to the new AWS-managed table by patching its ConfigMap and ServiceAccount.
