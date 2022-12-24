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

Create the Composite Definition
```bash
$ kubectl apply -f /workspace/modules/crossplane/compositions/definition.yaml
compositeresourcedefinition.apiextensions.crossplane.io "xrelationaldatabases.awsblueprints.io" deleted
```

## Create Composition

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

Create a Composition that provisions the managed resources `DBSubnetGroup`, `SecurityGroup` and `DBInstance`
```file
crossplane/compositions/composition.yaml
```

Create the Composition
```bash
$ kubectl apply -k /workspace/modules/crossplane/compositions
composition.apiextensions.crossplane.io/rds-mysql.awsblueprints.io created
```

## Create Composite Resource Claim 

Once you’ve configured Crossplane with the details of your new XR you can either create one directly, or use a claim. Typically only the folks responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

On this claim the developer only needs to specify a default database name, size, and location to store the credentials to connect to the database.

```file
crossplane/compositions/claim.yaml
```

Create the database by creating a Claim. (The namespace `catalog-prod` is created to store the credentials)
```bash
$ kubectl create ns catalog-prod || true
$ kubectl apply -f /workspace/modules/crossplane/compositions/claim.yaml
relationaldatabase.awsblueprints.io/rds-eks-workshop created
```


It takes some time to provision the AWS managed services, for RDS approximately 10 minutes. The AWS provider controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “Ready” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met. (Takes approximately 10 minutes, check RDS Console for progress)
```bash timeout=1200
$ kubectl wait relationaldatabase.awsblueprints.io rds-eks-workshop -n catalog-prod --for=condition=Ready --timeout=20m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Verify that the secret **catalog-db** has the correct information
```bash
$ export DB_INSTANCE=$(kubectl get dbinstances.rds.aws.crossplane.io -l 'crossplane.io/claim-name=rds-eks-workshop' -o jsonpath='{.items[*].status.atProvider.dbInstanceIdentifier}')
$ if [[ "$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == "\'${DB_INSTANCE}\'"].Endpoint.Address" --output text)" ==  "$(kubectl get secret catalog-db -o go-template='{{.data.endpoint|base64decode}}' -n catalog-prod)" ]]; then echo "Secret catalog configured correctly"; else echo "Error Catalo misconfigured"; false; fi
Secret catalog configured correctly
```


## Deploy the Application

The application will use the same manifest files as in development with the exception of the secret which contains the binding information that connects to AWS Services.

```bash
$ kubectl apply -k /workspace/modules/crossplane/manifests/
...
service/catalog created
...
deployment.apps/catalog created
...
```

## Access the Application

Verify that all pods are running in production

```bash
$ kubectl get pods -A | grep '\-prod'
assets-prod                    assets-7bd57dbfcc-cdp9j                         1/1     Running   0              1m
carts-prod                     carts-789498bdbd-wmb2q                          1/1     Running   0              1m
catalog-prod                   catalog-5c4b747759-7fphz                        1/1     Running   0              1m
checkout-prod                  checkout-66b6dcbc45-k9qjr                       1/1     Running   0              1m
orders-prod                    orders-59b94995cf-97pwz                         1/1     Running   0              1m
ui-prod                        ui-795bd46545-49jrh                             1/1     Running   0              1m
```

Get the hostname of the network load balancer for the UI and open it in the browser

```bash
$ kubectl get svc -n ui-prod ui-nlb
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                           PORT(S)        AGE
ui-nlb   LoadBalancer   x.x.x.x         k8s-uiprod-uinlb-<uuid>.elb.<region>.amazonaws.com    80:32028/TCP   111m
```

## Cleanup

Delete the Application
```bash timeout=600
$ kubectl delete -k /workspace/modules/crossplane/manifests/
```
Delete the Crossplane resources
```bash timeout=600
$ kubectl delete -f /workspace/modules/crossplane/compositions/claim.yaml
$ kubectl delete -f /workspace/modules/crossplane/compositions/definition.yaml
$ kubectl delete -k /workspace/modules/crossplane/compositions
$ kubectl delete ns catalog-prod
```