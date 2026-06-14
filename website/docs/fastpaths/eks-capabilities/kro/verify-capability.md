---
title: "Verify the kro capability"
sidebar_position: 20
---

`prepare-environment` enabled the kro capability on the cluster. Confirm it's `ACTIVE` and that kro's CRDs are registered before applying anything.

Inspect the capability resource directly:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_KRO_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

A capability transitions through `CREATING → ACTIVE`. If the status is anything else, wait a moment and re-run.

Check that kro's `ResourceGraphDefinition` CRD is registered:

```bash
$ kubectl get crd resourcegraphdefinitions.kro.run \
  -o jsonpath='{.spec.names.kind}{"\n"}'
ResourceGraphDefinition
```

```bash
$ kubectl api-resources --api-group=kro.run
NAME                       SHORTNAMES   APIVERSION         NAMESPACED   KIND
resourcegraphdefinitions   rgd          kro.run/v1alpha1   false        ResourceGraphDefinition
```

:::info
The `ResourceGraphDefinition` CRD is **cluster-scoped** (`NAMESPACED: false`). RGDs you create later are always cluster-wide. The instances of those RGDs — for example a `CartsStack` resource — are namespaced, because they own resources in a specific namespace.
:::

With the capability `ACTIVE` and the CRD in place, we're ready to define our first RGD.
