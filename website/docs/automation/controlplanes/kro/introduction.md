---
title: "Introduction"
sidebar_position: 3
---

kro operates within a cluster using two primary components:

1. The kro controller manager, which provides the core orchestration functionality
2. ResourceGraphDefinitions (RGDs), which define templates for creating groups of related resources

The kro controller manager watches for ResourceGraphDefinition custom resources and orchestrates the creation and management of the underlying Kubernetes resources defined in the template.

kro simplifies complex resource management by allowing platform teams to define ResourceGraphDefinitions that encapsulate multiple related resources. Developers interact with simple custom APIs defined by the RGD schema, while kro handles the complexity of creating and managing the underlying resources. This architecture provides a clear separation between the platform team, who defines the ResourceGraphDefinitions, and application developers, who consume the simplified custom APIs to create complex resource groups.

Let us first install kro to the Kubernetes cluster by using a Helm chart:

```bash wait=60
$ helm install kro oci://ghcr.io/kro-run/kro/kro \
  --version=${KRO_VERSION} \
  --namespace kro-system --create-namespace \
  --wait
```

Verify the kro controller is running:

```bash
$ kubectl get deployment -n kro-system
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
kro     1/1     1            1           13s
```

We can also verify that the kro custom resource definitions have been installed:

```bash
$ kubectl get crd | grep kro
resourcegraphdefinitions.kro.run          2025-10-15T22:34:13Z
```


## ResourceGraphDefinition Workflow

When you create a ResourceGraphDefinition, kro:

1. **Registers a new Custom API** - Based on the schema defined in the RGD, kro automatically creates a new Kubernetes CRD that developers can use
2. **Processes resource instances** - When developers create instances of the custom API, kro processes the request using the defined template
3. **Evaluates CEL expressions** - kro uses Common Expression Language (CEL) to evaluate conditions, pass values between resources, and determine the creation order
4. **Handles dependencies intelligently** - kro automatically analyzes how resources reference each other and determines the optimal deployment order without manual configuration
5. **Creates managed resources** - Based on the template and dependency analysis, kro creates the specified Kubernetes resources in the correct order
6. **Maintains relationships** - kro tracks dependencies between resources and ensures proper lifecycle management
