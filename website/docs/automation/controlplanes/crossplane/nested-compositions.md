---
title: "Nested Compositions"
sidebar_position: 40
---


First, lets provide a definition that can be used to create a database and the catalog service.

```file
automation/controlplanes/crossplane/app-db/composite/definition.yaml
```

Create this composite definition:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/app-db/composite/definition.yaml
compositeresourcedefinition.apiextensions.crossplane.io/xcatalogs.awsblueprints.io created
```

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

A Composition can include other Composite Resources which entels another Composition creating a "Nested Composition"

The following Composition provisions the composite resource `XRelationalDatabase` and managed resource for helm provider `CatalogService`


```file
automation/controlplanes/crossplane/app-db/compostion/composition.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/app-db/compostion/composition.yaml
composition.apiextensions.crossplane.io/catalog.awsblueprints.io created
```


Once we’ve configured Crossplane with the details of the new XR we can either create one directly or use a Claim. Typically only the team responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

With this claim the developer only needs to specify the database size (optional)

```file
automation/controlplanes/crossplane/app-db/claim/claim.yaml
```

Create the database by creating a `Claim`:

```bash
$ kubectl create ns nested --dry-run=client -o yaml | kubectl -f -
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/app-db/claim/claim.yaml
catalog.awsblueprints.io/catalog-claim created
```

It takes some time to provision the AWS managed services, in the case of RDS up to 10 minutes. Crossplane will report the status of the reconciliation in the status field of the Kubernetes custom resources.

To verify that the provisioning is done you can check that the condition “Ready” is true using the Kubernetes CLI. Run the following commands and they will exit once the condition is met:

```bash timeout=1200
$ kubectl wait catalog.awsblueprints.io catalog-nested -n nested --for=condition=Ready --timeout=20m
catalog.awsblueprints.io/catalog-nested condition met
```



Clean up, you can delete the claim
```bash test=false
$ kubectl delete -f /workspace/modules/automation/controlplanes/crossplane/app-db/claim/claim.yaml
catalog.awsblueprints.io "catalog-nested" deleted
```
