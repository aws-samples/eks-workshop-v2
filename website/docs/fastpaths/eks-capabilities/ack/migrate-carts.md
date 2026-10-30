---
title: "Migrate the carts service"
sidebar_position: 30
---

The DynamoDB table exists, but the `carts` Deployment is still pointed at the in-cluster `carts-dynamodb` Pod. Two changes flip it onto the AWS table:

1. **ConfigMap:** replace `RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT` and remove the `_CREATE_TABLE` flag (the table already exists).
2. **EKS Pod Identity:** bind the `carts` ServiceAccount to a pre-provisioned IAM role so the Pod can call DynamoDB. The role and its policy are created during `prepare-environment`; we just need to associate it with the ServiceAccount.

Inspect the kustomization that patches the ConfigMap:

```kustomization
modules/fastpaths/eks-capabilities/ack/carts/kustomization.yaml
ConfigMap/carts
```

:::note
The base-application's local `carts-dynamodb` Pod and Service stay in place. We're only flipping the application's pointer at the database, and cleanup will restore the original ConfigMap so other labs work normally.
:::

Apply the kustomization:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ack/carts \
  | envsubst | kubectl apply -f -
```

Bind the `carts` ServiceAccount to the IAM role via [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html). The role `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` was created by `prepare-environment` and already has access to both the `-carts` and `-carts-fastpath` tables:

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts --service-account carts | jq .
```

Restart the `carts` Pod so it picks up the new ConfigMap and the Pod Identity binding:

```bash timeout=120
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=90s
deployment "carts" successfully rolled out
```

Confirm the Pod sees the new table name and has Pod Identity credentials available:

```bash
$ kubectl exec -n carts deployment/carts -- env \
  | grep -E '^RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME='
RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME=...-carts-fastpath
```

```bash
$ kubectl exec -n carts deployment/carts -- env \
  | grep AWS_CONTAINER_CREDENTIALS_FULL_URI
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://...
```

The `AWS_CONTAINER_CREDENTIALS_FULL_URI` env var being present confirms Pod Identity is wiring the IAM role into the Pod. Every DynamoDB call the carts service makes will use the role's credentials, scoped to only the tables we provisioned.

That's the ACK lab done. The retail app is now backed by a real, AWS-managed DynamoDB table, provisioned and reconciled entirely from the Kubernetes API by an EKS capability.

Next, we'll deliver the `catalog` service via GitOps using the **Argo CD capability**.
