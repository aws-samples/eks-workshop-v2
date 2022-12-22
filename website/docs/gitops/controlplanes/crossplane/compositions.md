---
title: "Crossplane Compostions"
sidebar_position: 30
---

Using Compositions over directly using Managed Resources as we saw in the previous section, it allows for seperation of concenrs and for the platform team to provide
a way for the application team to create namespace resources that represent the AWS resources they need for their application.

## Create Composite Definition (XRD)

A `CompositeResourceDefinition` (or XRD) defines the type and schema of your Composite Resource (XR). It lets Crossplane know that you want a particular kind of XR to exist, and what fields that XR should have. An XRD is a little like a CustomResourceDefinition (CRD), but slightly more opinionated. Writing an XRD is mostly a matter of specifying an OpenAPI [“structural schema”](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).


Provide a definition to create a database by members of the application team in their corresponding namespace.
In this example the user only needs to specify `databaseName`, `storageGB` and `secret` location
```file
crossplane/compositions/definition.yaml
```

## Create Composition

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

Create a Composition that provisions the managed resources `DBSubnetGroup`, `SecurityGroup` and `DBInstance`
```file
crossplane/compositions/composition.yaml
```

## Create Composite Resource Claim 

Once you’ve configured Crossplane with the details of your new XR you can either create one directly, or use a claim. Typically only the folks responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

Create the database by creating a Claim
```file
crossplane/compositions/claim.yaml
```