---
title: "Creating a Composition"
sidebar_position: 10
---

A `CompositeResourceDefinition` (XRD) defines the type and schema of your Composite Resource (XR). It informs Crossplane about the desired XR and its fields. An XRD is similar to a CustomResourceDefinition (CRD) but with a more opinionated structure. Creating an XRD primarily involves specifying an OpenAPI ["structural schema"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).

Let's start by providing a definition that allows application team members to create a DynamoDB table in their respective namespaces. In this example, users only need to specify the **name**, **key attributes**, and **index name** fields.

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml
```

A Composition informs Crossplane about the actions to take when a Composite Resource is created. Each Composition establishes a link between an XR and a set of one or more Managed Resources. When the XR is created, updated, or deleted, the associated Managed Resources are correspondingly created, updated, or deleted.

The following Composition provisions the managed resource `Table`:

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml
```

Let's apply this configuration to our EKS cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

With these resources in place, we've successfully set up a Crossplane Composition for creating DynamoDB tables. This abstraction allows application developers to provision standardized DynamoDB tables without needing to understand the underlying AWS-specific details.
