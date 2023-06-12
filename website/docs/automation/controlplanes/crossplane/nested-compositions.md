---
title: "Nested Compositions"
sidebar_position: 40
---

:::tip Before you start
Prepare your environment for this section:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/compositions/definition.yaml
$ kubectl apply -k /workspace/modules/automation/controlplanes/crossplane/compositions/composition

```
:::

## Catalog Application
First, lets provide a definition that can be used to create a database and the catalog service.

```file
automation/controlplanes/crossplane/nested/composite/definition.yaml
```

Create this composite definition:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/nested/composite/definition.yaml
compositeresourcedefinition.apiextensions.crossplane.io/xcatalogs.awsblueprints.io created
```

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

A Composition can include other Composite Resources which entels another Composition creating a "Nested Composition"

The following Composition provisions the composite resource `XRelationalDatabase` and managed resource for helm provider `XCatalogService`


```file
automation/controlplanes/crossplane/nested/composition/composition.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/nested/composition/composition.yaml
composition.apiextensions.crossplane.io/catalog.awsblueprints.io created
```





## Catalog Service

First, lets provide a definition that can be used to create a database and the catalog service.

```file
automation/controlplanes/crossplane/nested/service/composite/definition.yaml
```


Create this composite definition:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/nested/service/composite/definition.yaml
compositeresourcedefinition.apiextensions.crossplane.io/xcatalogapps.awsblueprints.io created
```


The following Composition provisions the managed resources from Kubernetes provider `Deployment`, `ServiceAccount`, and `Service`


```file
automation/controlplanes/crossplane/nested/service/composition/composition.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/nested/service/composition/composition.yaml
composition.apiextensions.crossplane.io/catalog.awsblueprints.io created
```





## Catalog Claim


Once we’ve configured Crossplane with the details of the new XR we can either create one directly or use a Claim. Typically only the team responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

With this claim the developer only needs to specify the database size (optional)

```file
automation/controlplanes/crossplane/nested/claim/claim.yaml
```

Create the database and the serivce by creating a `Claim`:

```bash
$ kubectl create ns nested --dry-run=client -o yaml | kubectl apply -f -
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/nested/claim/claim.yaml
catalog.awsblueprints.io/catalog-claim created
```

It takes some time to provision the AWS managed services, in the case of RDS up to 10 minutes. Crossplane will report the status of the reconciliation in the status field of the Kubernetes custom resources.

To verify that the provisioning is done you can check that the condition “Ready” is true using the Kubernetes CLI. Run the following commands and they will exit once the condition is met:

```bash timeout=1200
$ kubectl wait catalog.awsblueprints.io catalog-nested -n nested --for=condition=Ready --timeout=20m
catalog.awsblueprints.io/catalog-nested condition met
```

Verify that the Catalog App deployed in the `nested` namespace connects to the RDS Database and returns products from the catalog

```bash
$ SERVICE_URL=$(kubectl get catalogs.awsblueprints.io catalog-nested -n nested --template="{{.status.serviceURL}}")
$ kubectl exec -n ui deploy/ui -- curl -s $SERVICE_URL/catalogue | jq .
[
  {
    "id": "510a0d7e-8e83-4193-b483-e27e09ddc34d",
    "name": "Gentleman",
    "description": "Touch of class for a bargain.",
    "imageUrl": "/assets/gentleman.jpg",
    "price": 795,
    "count": 51,
    "tag": [
      "dress"
    ]
  },
  {
    "id": "6d62d909-f957-430e-8689-b5129c0bb75e",
    "name": "Pocket Watch",
    "description": "Properly dapper.",
    "imageUrl": "/assets/pocket_watch.jpg",
    "price": 385,
    "count": 33,
    "tag": [
      "dress"
    ]
  },
...
```

Delete the claim:
```bash test=false
$ kubectl delete -f /workspace/modules/automation/controlplanes/crossplane/nested/claim/claim.yaml
catalog.awsblueprints.io "catalog-nested" deleted
```

