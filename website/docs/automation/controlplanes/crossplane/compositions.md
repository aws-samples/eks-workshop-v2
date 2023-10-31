---
title: "Compositions"
sidebar_position: 30
---

In addition to provisioning individual cloud resources, Crossplane offers a higher abstraction layer called Compositions. Compositions allow users to build opinionated templates for deploying cloud resources. For example, organizations may require certain tags to be present to all AWS resources or add specific encryption keys for all Amazon Simple Storage (S3) buckets. Platform teams can define these self-service API abstractions within Compositions and ensure that all the resources created through these Compositions meet the organization’s requirements.

A `CompositeResourceDefinition` (or XRD) defines the type and schema of your Composite Resource (XR). It lets Crossplane know that you want a particular kind of XR to exist, and what fields that XR should have. An XRD is a little like a CustomResourceDefinition (CRD), but slightly more opinionated. Writing an XRD is mostly a matter of specifying an OpenAPI ["structural schema"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).

First, lets provide a definition that can be used to create a database by members of the application team in their corresponding namespace. In this example the user only needs to specify `databaseName`, `storageGB` and `secret` location

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml
```

A Composition lets Crossplane know what to do when someone creates a Composite Resource. Each Composition creates a link between an XR and a set of one or more Managed Resources - when the XR is created, updated, or deleted the set of Managed Resources are created, updated or deleted accordingly.

The following Composition provisions the managed resources `Table`

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/composition.yaml
```

Apply this to our EKS cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

Once we’ve configured Crossplane with the details of the new XR we can either create one directly or use a Claim. Typically only the team responsible for configuring Crossplane (often a platform or SRE team) have permission to create XRs directly. Everyone else manages XRs via a lightweight proxy resource called a Composite Resource Claim (or claim for short).

With this claim the developer only needs to specify a default DynamoDB table name, hash keys, index to create the table. This allows the platform or SRE team to standardize on aspects for table creation.

```file
manifests/modules/automation/controlplanes/crossplane/compositions/claim/claim.yaml
```

Create the table by creating a `Claim`:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/claim/claim.yaml
dynamodbtable.awsblueprints.io/items created
```

It takes some time to provision the AWS managed services, in the case of DynamoDB up to 2 minutes. Crossplane will report the status of the reconciliation in the `SYNCED` field of the Kubernetes Composite and Managed resource.

```bash
$ kubectl get XDynamoDBTable
$ kubectl get table
```
When new resources are created or updated, application configurations also need to be updated to use these new resources. 
Update the application to use the DynamoDB endpoint:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/application
namespace/carts unchanged
serviceaccount/carts unchanged
configmap/carts unchanged
configmap/carts-crossplane created
service/carts unchanged
service/carts-dynamodb unchanged
deployment.apps/carts configured
deployment.apps/carts-dynamodb unchanged
$ kubectl rollout restart -n carts deployment/carts
$ kubectl rollout status -n carts deployment/carts --timeout=30s
```

----

Now, how do we know that the application is working with the new DynamoDB table?

An NLB has been created to expose the sample application for testing, allowing us to directly interact with the application through the browser:

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```
:::info
Please note that the actual endpoint will be different when you run this command as a new Network Load Balancer endpoint will be provisioned.
:::


To wait until the load balancer has finished provisioning you can run this command:

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Once the load balancer is provisioned you can access it by pasting the URL in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.png').default}/>
</browser>

To verify that the **Carts** module is in fact using the DynamoDB table we just provisioned, try adding a few items to the cart.

![Cart screenshot](./assets/cart-items-present.png)

And to check if items are in the DynamoDB table as well, run

```bash
aws dynamodb scan --table-name items
```


Congratulations! You've successfully created AWS Resources without leaving the confines of the Kubernetes API!