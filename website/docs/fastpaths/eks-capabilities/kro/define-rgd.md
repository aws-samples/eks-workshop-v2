---
title: "Define the CartsStack RGD"
sidebar_position: 20
---

Let's write the `CartsStack` RGD, the blueprint introduced on the previous page. Its two key sections are the `schema` (the inputs a user provides) and the `resources` (the graph kro creates from them):

::yaml{file="manifests/modules/fastpaths/eks-capabilities/kro/rgd/cartsstack-rgd.yaml" paths="spec.schema,spec.resources"}

1. **`spec.schema`** declares the shape of the user-facing CR using kro's **SimpleSchema** syntax (the `string | required=true` form), not raw OpenAPI. Optional fields like `image` and `replicas` get defaults, so a minimal instance only sets `tableName` and `namespace`.
2. **`spec.resources`** is the graph kro creates. Each entry has an `id` (used to reference its outputs from other resources) and a `template` (the actual manifest). Note the `${schema.spec.X}` references pulling in the user's inputs, and `${table.status...arn}` / `${sa.metadata.name}` references between resources, which is how kro infers the order to create them in.

Apply the RGD:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/kro/rgd
resourcegraphdefinition.kro.run/cartsstack created
```

kro validates the RGD synchronously: it type-checks every `${...}` expression against the actual Kubernetes schemas of the resources you reference, and detects circular dependencies. If anything is wrong, the apply fails immediately with a descriptive error.

Wait for the RGD to reach `Active`. At this point kro has dynamically generated and registered the `CartsStack` CRD in the cluster:

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
