---
title: "Apply a CartsStack instance"
sidebar_position: 30
---

## Pre-bind the Pod Identity association

Pod Identity is an EKS API, not a Kubernetes one, so it can't live in the RGD. Create the association first (EKS allows binding a ServiceAccount that doesn't exist yet), so the carts Pod boots with credentials already wired in. The role is the same wildcard-scoped `-carts-dynamo` role from the ACK lab, so it already covers the kro table:

```bash wait=10
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts-kro --service-account carts | jq '.association.associationId'
"a-..."
```

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
Compare with [the ACK lab](../ack/migrate-carts.md): the same end state took three separate `kubectl apply` steps plus an `aws eks create-pod-identity-association` call plus a `kubectl rollout restart`. Here, one `CartsStack` resource drives the whole graph, and a platform team only writes the RGD once for everyone who needs a carts-shaped stack.
:::

kro reconciles the six child resources in dependency order: it creates the `Namespace` first, then the `Table` (which the ACK DynamoDB controller starts provisioning in AWS), then the `ConfigMap` and `ServiceAccount` once the Namespace exists, and finally the `Deployment` and `Service` once the SA and ConfigMap they reference exist. The carts Pod boots with IAM credentials already injected by the Pod Identity association we created in the previous step.

Wait for the instance to reach `ACTIVE`:

```bash timeout=720
$ kubectl wait cartsstack carts-kro --for=jsonpath='{.status.state}'=ACTIVE --timeout=10m
cartsstack.kro.run/carts-kro condition met
```

:::note
This can take a few minutes. The instance only reports `ACTIVE` once every child is healthy, and the slowest child is the real DynamoDB table being created in AWS.
:::

## Inspect what kro created

Because the instance reached `ACTIVE`, kro has already created and health-checked every child. List them in the new namespace to see the whole graph from one apply:

```bash
$ kubectl -n carts-kro get table,configmap,serviceaccount,deployment,service
NAME                                    SYNCED   AGE
table.dynamodb.services.k8s.aws/items   True     ...

NAME                     DATA   AGE
configmap/carts          2      ...
configmap/kube-root-ca.crt   1  ...

NAME                   SECRETS   AGE
serviceaccount/carts   0         ...
serviceaccount/default 0         ...

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           ...

NAME            TYPE        CLUSTER-IP   PORT(S)   AGE
service/carts   ClusterIP   ...          80/TCP    ...
```

The `Table` shows `SYNCED=True`, meaning the ACK controller finished creating the real AWS table. Confirm it exists on the AWS side:

```bash
$ aws dynamodb describe-table \
  --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Table.TableStatus' --output text
ACTIVE
```

One `CartsStack` apply produced a full namespace of Kubernetes resources plus a real AWS DynamoDB table, with kro handling the ordering and health checks for you.

## Verify the Pod can reach DynamoDB

The carts Pod has a ServiceAccount, a ConfigMap pointing at the new table, IAM credentials via Pod Identity, and a network path to DynamoDB. Wait for the Deployment to be fully rolled out (Amazon EKS Auto Mode may still be scaling a node for the Pod), then confirm Pod Identity injected the role's credentials at Pod boot:

```bash timeout=180
$ kubectl rollout status -n carts-kro deployment/carts --timeout=150s
deployment "carts" successfully rolled out
$ kubectl exec -n carts-kro deployment/carts -- env \
  | grep AWS_CONTAINER_CREDENTIALS_FULL_URI
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://...
```

The `AWS_CONTAINER_CREDENTIALS_FULL_URI` env var being present confirms Pod Identity injected the role's credentials when the Pod was scheduled. The Pod is wired to the AWS DynamoDB table via:

- **ServiceAccount** → `aws eks create-pod-identity-association`
- → **IAM role `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`**
- → **AWS DynamoDB table `${EKS_CLUSTER_AUTO_NAME}-carts-kro`**

That's the kro lab done. You've defined a higher-level Kubernetes API (`CartsStack`) that composes ACK and native Kubernetes resources into a single resource, and a single instance produced a complete, running, IAM-bound carts service.

## Optional: see the kro lab's carts in the retail store UI

By default, the retail store's `ui` Pod talks to `carts.carts.svc`, which is the ACK lab's namespace (set by `RETAIL_UI_ENDPOINTS_CARTS` in the base UI ConfigMap). Repoint that same variable at the kro-managed carts service in `carts-kro` and restart the UI:

```bash test=false
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts-kro:80
$ kubectl -n ui rollout status deployment/ui --timeout=60s
deployment "ui" successfully rolled out
```

Expose the UI with an Ingress. Amazon EKS Auto Mode includes the AWS Load Balancer Controller, so applying an `Ingress` provisions a public Application Load Balancer automatically:

```bash test=false
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ui-ingress
```

Wait for the load balancer to finish provisioning (this takes a few minutes), then print its URL:

```bash test=false
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 30 --max-time 60 -k -s -o /dev/null \
  $(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://$(kubectl get ingress -n ui ui-auto -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')"
http://k8s-ui-uiauto-....us-west-2.elb.amazonaws.com
```

Open that URL in your browser. Because the ALB serves the app at the domain root, you can navigate the full store, including **Explore**. Add a couple of items to a cart; they'll land in the kro-managed `${EKS_CLUSTER_AUTO_NAME}-carts-kro` DynamoDB table:

```bash test=false
$ aws dynamodb scan --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Count' --output text
```

When you're done, remove the Ingress and revert the UI to the ACK lab's carts namespace:

```bash test=false
$ kubectl delete -n ui ingress ui-auto --ignore-not-found
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts.svc:80
$ kubectl -n ui rollout status deployment/ui --timeout=60s
```
