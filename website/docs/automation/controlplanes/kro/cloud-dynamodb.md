---
title: "Updating the application"
sidebar_position: 6
---

In this section, we will replace the in-memory database being used by carts with DynamoDB. We will do this by composing a WebApplicationDynamoDB ResourceGraphDefinition that builds on the base WebApplication template.

Let's examine the ResourceGraphDefinition template that defines the reusable WebApplicationDynamoDB API:

<details>
  <summary>Expand for full RGD manifest</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml"}

</details>

This ResourceGraphDefinition:
1. Creates a custom `WebApplicationDynamoDB` API that composes the WebApplication RGD
2. Provisions a DynamoDB table with ACK
3. Creates IAM roles and policies for DynamoDB access
4. Configures EKS Pod Identity for secure access from application pods

To learn more about EKS Pod Identity, refer to the [official documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).

:::info
Notice how this RGD includes the WebApplication RGD in its resources section. By referencing `webApplication`, this template reuses all the Kubernetes resources defined in the base WebApplication RGD while adding DynamoDB, IAM, and Pod Identity resources.
:::

Let's apply the ResourceGraphDefinition to register the WebApplicationDynamoDB API:

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml
resourcegraphdefinition.kro.run/web-application-ddb created
```

This registers the WebApplicationDynamoDB API. Verify the Custom Resource Definition (CRD):

```bash
$ kubectl get crd webapplicationdynamodbs.kro.run
NAME                               CREATED AT
webapplicationdynamodbs.kro.run    2024-01-15T10:35:00Z
```

Now let's examine the carts-ddb.yaml file that will use the WebApplicationDynamoDB API to create an instance of the **Carts** component:

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts-ddb.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.dynamodb,spec.env,spec.aws"}

1. Uses the custom WebApplicationDynamoDB API created by our RGD
2. Creates a resource named `carts` in the `carts` namespace
3. Specifies the application name for resource naming
4. Sets single replica
5. Uses the retail store cart service container image
6. Exposes the application on port 8080
7. Specifies the DynamoDB table name
8. Sets environment variables to enable DynamoDB persistence mode
9. Provides AWS account ID and region for IAM and Pod Identity configuration

First, let's delete the existing **Carts** component:

```bash
$ kubectl delete webapplication.kro.run/carts -n carts
webapplication.kro.run "carts" deleted
```

Next, let's deploy the updated component leveraging the carts-ddb.yaml file:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/kro/app \
  | envsubst | kubectl apply -f-
webapplicationdynamodb.kro.run/carts created
```

kro will process this custom resource and create all the underlying resources including the DynamoDB table. Let's verify the custom resource was created:

```bash
$ kubectl get webapplicationdynamodb -n carts
NAME    AGE
carts   30s
```

To verify that the DynamoDB table has been created, we can check the generated ACK resource:

```bash timeout=300
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

Let's confirm that the table has been created using the AWS CLI:

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-kro"
    ]
}
```

Perfect! Our DynamoDB table and component have been successfully created using kro's composable approach.

To verify that the component is working with the new DynamoDB table, we can interact with it through a browser. An NLB has been created to expose the sample application for testing:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-fe4dc7c11e-a362df3b7254c797.elb.us-west-2.amazonaws.com
```

:::info
Please note that the actual endpoint will be different when you run this command as a new Network Load Balancer endpoint will be provisioned.
:::

To wait until the load balancer has finished provisioning, you can run this command:

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Once the load balancer is provisioned, you can access it by pasting the URL in your web browser. You'll see the UI from the web store displayed and will be able to navigate around the site as a user.

<Browser url="http://k8s-ui-uinlb-fe4dc7c11e-a362df3b7254c797.elb.us-west-2.amazonaws.com/">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

To verify that the **Carts** module is indeed using the DynamoDB table we just provisioned, try adding a few items to the cart.

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

To confirm that these items are also in the DynamoDB table, run:

```bash
$ aws dynamodb scan --table-name "eks-workshop-carts-kro"
```

Congratulations! We have successfully demonstrated kro's composability by building on the base WebApplication template to add DynamoDB storage.

