---
title: "Provisioning ACK resources"
sidebar_position: 5
---

By default, the **Carts** component in the sample application uses a DynamoDB local instance running as a pod in the EKS cluster called `carts-dynamodb`. In this section of the lab, we'll provision an Amazon DynamoDB cloud-based table for our application using Kubernetes custom resources and configure the **Carts** deployment to use this newly provisioned DynamoDB table instead of the local copy.

![ACK reconciler concept](./assets/ack-desired-current-ddb.webp)

Let's examine how we can create the DynamoDB Table using a Kubernetes manifest:

::yaml{file="manifests/modules/automation/controlplanes/ack/dynamodb/dynamodb-create.yaml" paths="apiVersion,kind,spec.keySchema,spec.attributeDefinitions,spec.billingMode,spec.tableName,spec.globalSecondaryIndexes"}

1. Uses ACK DynamoDB controller
2. Creates a DynamoDB table resource
3. Specify Primary key using `id` attribute as partition key (`HASH`)
4. Defines `id` and `customerId` as string attributes
5. Specifies On-demand pricing model
6. Specifies the DynamoDB table name using the `${EKS_CLUSTER_NAME}` environment variable prefix
7. Creates a global secondary index named `idx_global_customerId` that enables efficient queries by `customerID` with all table attributes projected

:::info
Keen observers will notice that the YAML specification closely resembles the [API signature](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html) for DynamoDB, including familiar fields such as `tableName` and `attributeDefinitions`.
:::

Now, let's apply these updates to the cluster:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/ack/dynamodb \
  | envsubst | kubectl apply -f-
table.dynamodb.services.k8s.aws/items created
```

The ACK controllers in the cluster will respond to these new resources and provision the AWS infrastructure we've defined in the manifests. To verify that ACK has created the table, run the following command:

```bash timeout=300
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

Finally, let's confirm that the table has been created using the AWS CLI:

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-ack"
    ]
}
```

This output confirms that our new table has been successfully created!

By leveraging ACK, we've seamlessly provisioned a cloud-based DynamoDB table directly from our Kubernetes cluster, demonstrating the power and flexibility of this approach to managing AWS resources.
