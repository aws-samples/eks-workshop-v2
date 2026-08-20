---
title: "Provision a DynamoDB table"
sidebar_position: 20
---

We can now define a real DynamoDB table as a Kubernetes resource. Take a look at the manifest:

::yaml{file="manifests/modules/fastpaths/eks-capabilities/ack/dynamodb/table.yaml" paths="kind,spec.tableName,spec.billingMode,spec.keySchema,spec.globalSecondaryIndexes"}

1. Uses the ACK DynamoDB controller's `Table` custom resource.
2. Names the table after the cluster (`${EKS_CLUSTER_AUTO_NAME}-carts-fastpath`) so parallel workshop runs don't collide.
3. Uses on-demand pricing.
4. Defines the partition key schema, matching what the `carts` service expects.
5. Adds a global secondary index on `customerId` so the service can query carts by customer.

:::info
The YAML closely mirrors the [DynamoDB `CreateTable` API](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html). Anything you can express through the API is expressible here.
:::

Apply the manifest:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ack/dynamodb \
  | envsubst | kubectl apply -f -
table.dynamodb.services.k8s.aws/items created
```

The capability's DynamoDB controller picks up the new `Table` resource and provisions the corresponding AWS resource. Wait for the `ACK.ResourceSynced` condition, which is how every ACK resource signals it has reconciled successfully:

```bash timeout=720
$ kubectl wait table.dynamodb.services.k8s.aws items \
  -n carts --for=condition=ACK.ResourceSynced --timeout=10m
table.dynamodb.services.k8s.aws/items condition met
```

Inspect the resource status:

```bash
$ kubectl get table.dynamodb.services.k8s.aws items -n carts \
  -o jsonpath='{.status.tableStatus}{"\n"}'
ACTIVE
```

Finally, confirm the table exists in AWS:

```bash
$ aws dynamodb describe-table \
  --table-name "$EKS_CAP_DDB_TABLE" \
  --query 'Table.TableStatus' --output text
ACTIVE
```

We've created a real DynamoDB table without ever leaving the Kubernetes API. The capability handled both the controller infrastructure and the IAM permissions needed to call the DynamoDB API.
