---
title: "Apply a CartsStack instance"
sidebar_position: 40
---

We're about to apply a single `CartsStack` CR and watch kro fan it out into six Kubernetes resources plus an AWS DynamoDB table. Before we do, there's one piece kro can't manage on its behalf:

## Pre-bind the Pod Identity association

The carts container is a Spring Boot service that calls AWS DynamoDB on startup — it needs IAM credentials and a region from the moment it boots. Pod Identity is an **EKS API**, not a Kubernetes API, so kro can't include it in the RGD.

We solve this by **pre-creating** the Pod Identity association before the carts Pod ever exists. EKS allows registering an association for a namespace + ServiceAccount that doesn't exist yet — the binding becomes active the moment the SA appears in the cluster:

```bash wait=10
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts-kro --service-account carts | jq '.association.associationId'
"a-..."
```

The IAM role `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` is the same role from Lab 1, wildcard-scoped to `${EKS_CLUSTER_AUTO_NAME}-carts-*` — it already covers the kro-managed table without changes.

:::info
Pod Identity is an EKS API rather than a Kubernetes API, so kro can't manage it directly inside the RGD. The split is intentional: kro composes Kubernetes resources, and an external one-line `aws eks` call binds the AWS-side identity. By creating the association _before_ applying the CartsStack, the carts Pod's first boot has its IAM credentials already wired in. Adding the ACK eks controller would let the RGD include a `PodIdentityAssociation` CR and remove this pre-step — out of scope for this lab, but a natural extension for a platform team.
:::

## Apply the CartsStack instance

The instance manifest is small:

```yaml
apiVersion: kro.run/v1alpha1
kind: CartsStack
metadata:
  name: carts-kro
  namespace: default
spec:
  tableName: ${EKS_CLUSTER_AUTO_NAME}-carts-kro
  namespace: carts-kro
```

Apply it:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/kro/instance \
  | envsubst | kubectl apply -f -
cartsstack.kro.run/carts-kro created
```

:::tip
Compare with [Lab 1](../ack/migrate-carts.md): the same end state took three separate `kubectl apply` steps plus an `aws eks create-pod-identity-association` call plus a `kubectl rollout restart`. Here, one `CartsStack` CR drives the whole graph — and a platform team only writes the RGD once for everyone who needs a carts-shaped stack.
:::

kro reconciles the six child resources in dependency order: it creates the `Namespace` first, then the `Table` (which the ACK DynamoDB controller starts provisioning in AWS), then the `ConfigMap` and `ServiceAccount` once the Namespace exists, and finally the `Deployment` and `Service` once the SA and ConfigMap they reference exist. The carts Pod boots with IAM credentials already injected by the Pod Identity association we created in the previous step.

Wait for the instance to reach `ACTIVE`:

```bash timeout=720
$ kubectl wait cartsstack carts-kro --for=jsonpath='{.status.state}'=ACTIVE --timeout=10m
cartsstack.kro.run/carts-kro condition met
```

:::note
The wait timeout is generous because the bottleneck is the ACK DynamoDB controller actually creating the AWS DynamoDB table — a single instance creates one table from cold and the kro instance does not reach `ACTIVE` until every child resource it owns is healthy.
:::

## Inspect what kro created

The Namespace, ConfigMap, and ServiceAccount appeared in the new namespace:

```bash
$ kubectl get ns carts-kro
NAME        STATUS   AGE
carts-kro   Active   ...
$ kubectl -n carts-kro get configmap/carts serviceaccount/carts
NAME              DATA   AGE
configmap/carts   2      ...

NAME                   SECRETS   AGE
serviceaccount/carts   0         ...
```

Wait for the carts Deployment to roll out — its readiness probe takes ~30 seconds after the Pod becomes ready:

```bash timeout=180
$ kubectl -n carts-kro rollout status deployment/carts --timeout=120s
deployment "carts" successfully rolled out
```

Inspect the Deployment and Service:

```bash
$ kubectl -n carts-kro get deployment/carts service/carts
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           ...

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/carts   ClusterIP   ...             <none>        80/TCP    ...
```

The ACK `Table` is reconciled and `ACK.ResourceSynced=True`:

```bash
$ kubectl -n carts-kro get table.dynamodb.services.k8s.aws items \
  -o jsonpath='{.status.tableStatus}{"\n"}'
ACTIVE
```

And the AWS-side DynamoDB table exists:

```bash
$ aws dynamodb describe-table \
  --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Table.TableStatus' --output text
ACTIVE
```

A single `CartsStack` apply produced six Kubernetes resources, a real AWS DynamoDB table, and a running carts Pod — all without the learner having to think about ordering or status conditions.

## Verify the Pod can reach DynamoDB

The carts Pod has a ServiceAccount, a ConfigMap pointing at the new table, IAM credentials via Pod Identity, and a network path to DynamoDB. Confirm Pod Identity injected the role's credentials at Pod boot:

```bash
$ kubectl exec -n carts-kro deployment/carts -- env \
  | grep AWS_CONTAINER_CREDENTIALS_FULL_URI
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://...
```

The `AWS_CONTAINER_CREDENTIALS_FULL_URI` env var being present confirms Pod Identity injected the role's credentials when the Pod was scheduled. The Pod is wired to the AWS DynamoDB table via:

- **ServiceAccount** → `aws eks create-pod-identity-association`
- → **IAM role `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`**
- → **AWS DynamoDB table `${EKS_CLUSTER_AUTO_NAME}-carts-kro`**

That's Lab 3 done. You've defined a higher-level Kubernetes API (`CartsStack`) that composes ACK and native Kubernetes resources into a single CR — and a single instance produced a complete, running, IAM-bound carts service.

## Optional: see Lab 3's carts in the retail store UI

By default, the retail store's `ui` Pod talks to `carts.carts.svc.cluster.local` — Lab 1's namespace. To temporarily route the UI at the kro-managed carts service in `carts-kro` instead, repoint the env var and restart the UI:

```bash test=false
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS_URL=http://carts.carts-kro:80
$ kubectl -n ui rollout status deployment/ui --timeout=60s
deployment "ui" successfully rolled out
```

Now port-forward the UI Service so you can hit it from the IDE's browser preview:

```bash test=false
$ kubectl port-forward -n ui svc/ui 8080:80
```

In the workshop IDE, a popup appears showing forwarded ports — click to open `http://localhost:8080`. Add a couple of items to a cart in the browser; they'll land in the kro-managed `${EKS_CLUSTER_AUTO_NAME}-carts-kro` DynamoDB table:

```bash test=false
$ aws dynamodb scan --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Count' --output text
```

Press `CTRL+C` to break the port-forward.

To revert the UI back to Lab 1's carts namespace:

```bash test=false
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS_URL-
$ kubectl -n ui rollout status deployment/ui --timeout=60s
```
