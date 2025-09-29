---
title: "Creating a Composition"
sidebar_position: 10
---

A `CompositeResourceDefinition` (XRD) defines the type and schema of your Composite Resource (XR). It informs Crossplane about the desired XR and its fields. An XRD is similar to a CustomResourceDefinition (CRD) but with a more opinionated structure. Creating an XRD primarily involves specifying an OpenAPI ["structural schema"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).

Let's start by providing a definition that allows application team members to create a DynamoDB table in their respective namespaces. In this example, users only need to specify the **name**, **key attributes**, and **index name** fields.

<details>
  <summary>Expand for full XRD manifest</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml"}

</details>

We can review the DynamoDB-specific configuration from the XRD manifest. 

Here is the section requiring the specification of the DynamoDB Table Name:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.resourceConfig.properties.name.type" zoomBefore="9"}

This section provides the specification of the DynamoDB Table key attributes:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.rangeKey" zoomBefore="20"}

This is the section on the Global Secondary Index specification:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.globalSecondaryIndex.type" zoomBefore="23"}

This is the section on the Local Secondary Index specification:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.localSecondaryIndex.type" zoomBefore="19"}

A Composition informs Crossplane about the actions to take when a Composite Resource is created. Each Composition establishes a link between an XR and a set of one or more Managed Resources. When the XR is created, updated, or deleted, the associated Managed Resources are correspondingly created, updated, or deleted.

<details>
  <summary>Expand to view the Composition that provisions the managed resource `Table`:</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml"}

</details>

We can review this in several parts to make better sense of it. 

This section maps the XR's `spec.name` field to the Managed Resource's external-name annotation, which Crossplane uses to set the actual DynamoDB table name in AWS.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.patchSets.0.patches.1.toFieldPath" zoomBefore="2"}

This transfers all attribute definitions from the XR to the managed DynamoDB resource, enabling Crossplane to create the table schema with proper data types.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.1.policy.mergeOptions" zoomBefore="4"}

This maps the first attribute from the XR as the partition key (hash key) for the DynamoDB table's primary key structure.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.3.toFieldPath" zoomBefore="2"}

This transfers the GSI name from the XR specification to the managed resource, allowing Crossplane to create the named global secondary index on the DynamoDB table.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.8.toFieldPath" zoomBefore="2"}

This maps LSI configurations from the XR to the managed resource, enabling Crossplane to provision local secondary indexes with their specified names and attributes.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.11.toFieldPath" zoomBefore="2"}


Let's apply this configuration to our EKS cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

With these resources in place, we've successfully set up a Crossplane Composition for creating DynamoDB tables. This abstraction allows application developers to provision standardized DynamoDB tables without needing to understand the underlying AWS-specific details.
