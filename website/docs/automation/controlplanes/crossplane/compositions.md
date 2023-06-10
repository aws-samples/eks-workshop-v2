---
title: "Compositions"
sidebar_position: 30
---

In addition to provisioning individual cloud resources, Crossplane offers a higher abstraction layer called Compositions. Compositions allow users to build opinionated templates for deploying cloud resources. For example, organizations may require certain tags to be present to all AWS resources or add specific encryption keys for all Amazon Simple Storage (S3) buckets. Platform teams can define these self-service API abstractions within Compositions and ensure that all the resources created through these Compositions meet the organization’s requirements.

A `CompositeResourceDefinition` (or XRD) defines the type and schema of your Composite Resource (XR). It lets Crossplane know that you want a particular kind of XR to exist, and what fields that XR should have. An XRD is a little like a CustomResourceDefinition (CRD), but slightly more opinionated. Writing an XRD is mostly a matter of specifying an OpenAPI ["structural schema"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).

First, lets provide a definition that can be used to create a database by members of the application team in their corresponding namespace. In this example the user only needs to specify `databaseName`, `dbInstanceClass`, `storageGB` and `secret` location

```file
automation/controlplanes/crossplane/compositions/definition.yaml
```

Create this composite definition:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/compositions/definition.yaml
compositeresourcedefinition.apiextensions.crossplane.io/xrelationaldatabases.awsblueprints.io created
```

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

The following Composition provisions the managed resources `DBSubnetGroup`, `SecurityGroup` and `DBInstance`

The `DBInstance` is configure to auto generate the DB password, and store it in a Kubernetes secret with
the name specified in the claim `spec.secret` in the same namespace as the claim. The location of the secret
is specified by `masterUserPasswordSecretRef`. The DB username and endpoint values are stored in the same
secret specified by `spec.writeConnectionSecretToRef`:

```file
automation/controlplanes/crossplane/compositions/composition/composition.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -k /workspace/modules/automation/controlplanes/crossplane/compositions/composition
composition.apiextensions.crossplane.io/rds-mysql.awsblueprints.io created
```

Once we’ve configured Crossplane with the details of the new XR we can either create one directly or use a Claim. Typically only the team responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

With this claim the developer only needs to specify a default database name, database instance class, size, and location to store the credentials to connect to the database. This allows the platform or SRE team to standardize on aspects such as database engine, high-availability architecture and security configuration.

```file
automation/controlplanes/crossplane/compositions/claim/claim.yaml
```

Create the database by creating a `Claim`:

```bash
$ kubectl apply -f /workspace/modules/automation/controlplanes/crossplane/compositions/claim/claim.yaml
relationaldatabase.awsblueprints.io/catalog-composition created
```

It takes some time to provision the AWS managed services, in the case of RDS up to 10 minutes. Crossplane will report the status of the reconciliation in the status field of the Kubernetes custom resources.

To verify that the provisioning is done you can check that the condition “Ready” is true using the Kubernetes CLI. Run the following commands and they will exit once the condition is met:

```bash timeout=1200
$ kubectl wait relationaldatabase.awsblueprints.io catalog-composition -n catalog --for=condition=Ready --timeout=20m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Crossplane will have automatically created a Kubernetes secret object that contains the credentials to connect to the RDS instance.


Verify that you can access RDS instance using the credentials specified in the claim:
```bash
$ DB_USERNAME=$(kubectl get secret catalog-db-composition -n catalog --template="{{index .data.username | base64decode}}")
$ DB_PASSWORD=$(kubectl get secret catalog-db-composition -n catalog --template="{{index .data.password | base64decode}}")
$ DB_ENDPOINT=$(kubectl get secret catalog-db-composition -n catalog --template="{{index .data.endpoint | base64decode}}")
$ DB_PORT=$(kubectl get secret catalog-db-composition -n catalog --template="{{index .data.port | base64decode}}")
$ echo $DB_USERNAME $DB_PASSWORD $DB_ENDPOINT $DB_PORT
$ kubectl run -n catalog mysql-client --image=mysql:8 -it --rm --restart=Never -- \
mysql -h $DB_ENDPOINT -u$DB_USERNAME -p$DB_PASSWORD -e \
'set sql_notes=0;show databases like "catalog";'
+--------------------+
| Database (catalog) |
+--------------------+
| catalog            |
+--------------------+
```


Delete the claim:
```bash test=false
$ kubectl delete -f /workspace/modules/automation/controlplanes/crossplane/app-db/claim/claim.yaml
catalog.awsblueprints.io "catalog-nested" deleted
```
