---
title: "Creating a Composition"
sidebar_position: 10
---

A `CompositeResourceDefinition` (or XRD) defines the type and schema of your Composite Resource (XR). It lets Crossplane know that you want a particular kind of XR to exist, and what fields that XR should have. An XRD is a little like a CustomResourceDefinition (CRD), but slightly more opinionated. Writing an XRD is mostly a matter of specifying an OpenAPI ["structural schema"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).

First, lets provide a definition that can be used to create a DynamoDB table by members of the application team in their corresponding namespace. In this example the user only needs to specify **name**, **key attributes** and **index name** fields.

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml
```

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

The following Composition provisions the managed resources `Table`

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```
