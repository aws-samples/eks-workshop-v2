---
title: "Provisioning resources with kro"
sidebar_position: 5
---

Now that kro has been installed, we will deploy the **Carts** application using a kro WebApplication ResourceGraphDefinitions. First, let's examine the ResourceGraphDefinition template that defines the reusable WebApplication API:

<details>
  <summary>Expand for full RGD manifest</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml"}

</details>

This ResourceGraphDefinition creates a custom `WebApplication` API that abstracts the complexity of deploying:
- ServiceAccount
- ConfigMap
- Deployment
- Service
- Ingress (optional)

The schema provides sensible defaults while allowing customization of key parameters like the application image, replica count, environment variables, and health check configuration as shown:

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml" zoomPath="spec.schema.spec" zoomBefore="0"}

:::info
Notice how the schema uses default values and type definitions to create a developer-friendly API that hides the underlying Kubernetes complexity.
:::

We will use this WebApplication ResourceGraphDefinition to create an instance of the Carts service which uses an in-memory database. To do this, let's first clean up the existing carts deployment:

```bash
$ kubectl delete all --all -n carts
pod "carts-68d496fff8-9lcpc" deleted
pod "carts-dynamodb-995f7768c-wtsbr" deleted
service "carts" deleted
service "carts-dynamodb" deleted
deployment.apps "carts" deleted
deployment.apps "carts-dynamodb" deleted
```

Next, apply the ResourceGraphDefinition to register the WebApplication API:

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml
resourcegraphdefinition.kro.run/web-application created
```

This registers the WebApplication API. Verify the Custom Resource Definition (CRD):

```bash
$ kubectl get crd webapplications.kro.run
NAME                       CREATED AT
webapplications.kro.run    2024-01-15T10:30:00Z
```

Now let's examine the `carts.yaml` file that will use the WebApplication API to create an instance of the carts application:

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.env,spec.service"}

1. Uses the custom WebApplication API created by our RGD
2. Creates a resource named `carts` in the `carts` namespace
3. Specifies the application name for resource naming
4. Sets single replica
5. Uses the retail store cart service container image
6. Exposes the application on port 8080
7. Configures environment variables for in-memory persistence mode
8. Enables the Kubernetes Service resource

Let's deploy the application:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/app/carts.yaml
webapplication.kro.run/carts created
```

kro will process this custom resource and create all the underlying Kubernetes resources. Let's verify the custom resource was created:

```bash
$ kubectl get webapplication -n carts
NAME    AGE
carts   30s
```

Next, verify the deployment:

```bash
$ kubectl get all -n carts
NAME                         READY   STATUS    RESTARTS   AGE
pod/carts-7d58cfb7c9-xyz12   1/1     Running   0          30s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/carts   ClusterIP   172.20.123.45   <none>        80/TCP    30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           30s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/carts-7d58cfb7c9   1         1         1       30s
```

Perfect! kro has successfully orchestrated the deployment of all Kubernetes resources required by the carts application as a single unit.

:::info
By using kro, we've transformed what would typically require applying multiple YAML files into a single, declarative API call. This demonstrates kro's power in simplifying complex resource orchestration.
:::

In the next section, we'll replace the in-memory database that is currently being used by carts with an Amazon DynamoDB table.
