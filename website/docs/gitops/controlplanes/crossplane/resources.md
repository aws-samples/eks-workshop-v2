---
title: "Resources"
sidebar_position: 20
---

Lets look at provisioning AWS resources using Crossplane Managed Resources.
Managed resouces are Kubernetes resources that are cluster scoped.
A Kuberentes user or tool will need cluster scope permission to create this type of resources.

We will deploy a RDS database instance for the Catalog microservice

Create the namespace `catalog-prod`, this is the namespace the database password and endpoint values will be saved.
```bash
$ kubectl create ns catalog-prod
```

Specify a Security Group manifest, this controls access to our database.
```file
crossplane/managed/rds-security-group.yaml
```
Specify a RDS DBSubnetGroup manifest, this configures the subnets that the database will be attach
```file
crossplane/managed/rds-dbgroup.yaml
```
Specify a RDS DBInstance manifest, this configures the database configuration like storage and engine.
```file
crossplane/managed/rds-instance.yaml
```

Create SecurityGroup, DBSubnetGroup, and DBInstance using the manifest files.
```bash
$ kubectl apply -k /workspace/modules/crossplane/managed
dbsubnetgroup.database.aws.crossplane.io/rds-eks-workshop created
securitygroup.ec2.aws.crossplane.io/rds-eks-workshop created
dbinstance.rds.aws.crossplane.io/rds-eks-workshop created
```

