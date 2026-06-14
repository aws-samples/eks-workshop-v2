---
title: "Define the CartsStack RGD"
sidebar_position: 30
---

A **ResourceGraphDefinition** is the heart of kro: it declares a new Kubernetes API kind and the graph of resources that get created whenever someone applies an instance of that kind.

The `CartsStack` RGD we'll define in this lab takes a couple of simple inputs (`tableName`, `namespace`, plus optional `image` and `replicas`) and expands into the full carts stack — a `Namespace`, an ACK `Table`, a `ConfigMap`, a `ServiceAccount`, a `Deployment` running the carts container, and a `Service` so other components can reach it. Here's an excerpt of the manifest we'll apply:

```yaml
apiVersion: kro.run/v1alpha1
kind: ResourceGraphDefinition
metadata:
  name: cartsstack
spec:
  schema:
    apiVersion: v1alpha1
    kind: CartsStack
    group: kro.run
    spec:
      tableName: string | required=true
      namespace: string | required=true
      image: string | default="public.ecr.aws/aws-containers/retail-store-sample-cart:1.2.1"
      replicas: integer | default=1
    status:
      tableArn: ${table.status.ackResourceMetadata.arn}
  resources:
    - id: ns
      template:
        apiVersion: v1
        kind: Namespace
        metadata: { name: ${schema.spec.namespace} }
    - id: table
      template:
        apiVersion: dynamodb.services.k8s.aws/v1alpha1
        kind: Table
        metadata: { name: items, namespace: ${schema.spec.namespace} }
        spec:
          tableName: ${schema.spec.tableName}
          billingMode: PAY_PER_REQUEST
          # ...key schema + GSI omitted for brevity
    - id: sa
      template:
        apiVersion: v1
        kind: ServiceAccount
        metadata: { name: carts, namespace: ${schema.spec.namespace} }
    - id: config
      template:
        apiVersion: v1
        kind: ConfigMap
        metadata: { name: carts, namespace: ${schema.spec.namespace} }
        data:
          RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
          RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: ${schema.spec.tableName}
    - id: deployment
      template:
        apiVersion: apps/v1
        kind: Deployment
        metadata: { name: carts, namespace: ${schema.spec.namespace} }
        spec:
          replicas: ${schema.spec.replicas}
          # ...selector, podSpec wired to the SA + ConfigMap above
    - id: service
      template:
        apiVersion: v1
        kind: Service
        metadata: { name: carts, namespace: ${schema.spec.namespace} }
        spec:
          type: ClusterIP
          ports: [{ port: 80, targetPort: http, name: http }]
```

A few things to notice:

- **`spec.schema`** declares the shape of the user-facing CR. kro uses a **SimpleSchema** syntax (the `string | required=true` form), not raw OpenAPI. Optional fields like `image` and `replicas` get sensible defaults so a minimal instance only has to set `tableName` and `namespace`.
- **`spec.resources`** is the graph kro will create. Each entry has an `id` (used to reference its outputs from other resources) and a `template` (the actual manifest).
- **`${schema.spec.X}`** references fields from the user's instance. **`${table.status.ackResourceMetadata.arn}`** references runtime status from another resource — kro orders the graph so `table` is created before anything that reads its status.
- **`${sa.metadata.name}`** and **`${config.metadata.name}`** in the Deployment template are how the Pod's `serviceAccountName` and `envFrom.configMapRef.name` get wired up — kro infers the dependency from these references, so the Deployment is created only after the SA and ConfigMap exist.

Apply the RGD:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/kro/rgd
resourcegraphdefinition.kro.run/cartsstack created
```

kro validates the RGD synchronously: it type-checks every `${...}` expression against the actual Kubernetes schemas of the resources you reference, and detects circular dependencies. If anything is wrong, the apply fails immediately with a descriptive error.

Wait for the RGD to reach `Active` — at this point kro has dynamically generated and registered the `CartsStack` CRD in the cluster:

```bash timeout=120
$ kubectl wait rgd cartsstack --for=jsonpath='{.status.state}'=Active --timeout=60s
resourcegraphdefinition.kro.run/cartsstack condition met
```

Confirm the new `CartsStack` kind is now a first-class Kubernetes API:

```bash
$ kubectl api-resources --api-group=kro.run | grep -E 'NAME|cartsstacks'
NAME                       SHORTNAMES   APIVERSION         NAMESPACED   KIND
cartsstacks                             kro.run/v1alpha1   true         CartsStack
```

:::info
`cartsstacks` is **namespaced** even though the RGD that defines it is cluster-scoped. RGDs live cluster-wide; instances always live in a specific namespace.
:::

The schema exists. Next we'll apply an instance.
