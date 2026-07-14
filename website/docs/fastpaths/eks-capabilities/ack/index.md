---
title: "Provision AWS resources with ACK"
sidebar_position: 10
---

::required-time{estimatedLabExecutionTimeMinutes="10"}

By default, the `carts` component in the sample application stores data in a [DynamoDB local](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) instance running as a Pod called `carts-dynamodb`. This is convenient for development, but in testing and production you typically want a real Amazon DynamoDB table so your team can focus on the application rather than operating a database. In this lab we will provision a real DynamoDB table from Kubernetes using [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/), then point the `carts` Deployment at it.

You can run ACK yourself by installing its controllers into the cluster with a Helm chart, as shown in the [self-managed ACK lab](/docs/automation/controlplanes/ack). When you do, you also own their day-two operations: scaling, patching, upgrades, and the IAM wiring each controller needs. This lab uses the **ACK EKS capability** instead. The controllers run in AWS-owned infrastructure separate from your cluster, and AWS handles their scaling, patching, and upgrades. There is no `ack-system` namespace, no controller Deployment on your nodes, and no `helm install ack-dynamodb-controller` step. You declare the AWS resource you want, and the managed capability reconciles it.

:::info
Amazon EKS Capabilities offload the operation of platform components such as ACK to AWS, so you can focus on deploying applications rather than maintaining platform infrastructure. Learn more in the [Amazon EKS Capabilities announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/).
:::

:::tip What's been set up for you

- The **ACK EKS-managed capability** is enabled on the cluster, with the DynamoDB controller selected. The capability assumes an IAM Capability Role scoped to a single DynamoDB table named `${EKS_CLUSTER_AUTO_NAME}-carts-fastpath`.
- An **IAM role** for the `carts` ServiceAccount is pre-provisioned (`${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`) so the application Pod can read and write the table via [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).
- The base retail application is running with `carts` pointing at the in-cluster `carts-dynamodb` Pod.

:::

Throughout this lab, we will:

1. Verify the ACK capability is `ACTIVE` and the DynamoDB Custom Resource Definitions (CRDs) are present in the cluster.
2. Provision a DynamoDB table by applying a Kubernetes `Table` resource.
3. Migrate the `carts` Deployment from the in-cluster DynamoDB Pod to the new AWS-managed table by updating its ConfigMap and ServiceAccount.

## Verify the capability

Before provisioning anything, confirm the capability is `ACTIVE`. Inspect it directly:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ACK_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

A capability transitions through `CREATING → ACTIVE`. If the status is anything other than `ACTIVE`, wait a moment and re-run the command, as the capability may still be initializing.

Now confirm the DynamoDB controller's CRDs are registered in the cluster:

```bash
$ kubectl get crd tables.dynamodb.services.k8s.aws \
  -o jsonpath='{.spec.names.kind}{"\n"}'
Table
```

```bash
$ kubectl api-resources --api-group=dynamodb.services.k8s.aws
NAME             SHORTNAMES   APIVERSION                              NAMESPACED   KIND
backups                       dynamodb.services.k8s.aws/v1alpha1      true         Backup
globaltables                  dynamodb.services.k8s.aws/v1alpha1      true         GlobalTable
tables                        dynamodb.services.k8s.aws/v1alpha1      true         Table
```

Consistent with a managed capability, there is no `ack-system` namespace and no controller Pod on your worker nodes. What you see inside the cluster are only the CRDs the capability registered for you to apply against. With the capability `ACTIVE` and the CRDs in place, we're ready to provision a DynamoDB table from Kubernetes.
