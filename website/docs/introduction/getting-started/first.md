---
title: Deploying components
sidebar_position: 30
---

# Deploying Components

Now that you understand the application architecture, let's deploy it step by step. We'll start with a single component to see how your Kubernetes knowledge applies in practice.

## Understanding the Manifests

The sample application is composed of Kubernetes manifests organized for easy deployment with Kustomize. Since you've learned about Pods, Deployments, Services, and Configuration, you'll recognize these concepts in the manifests.

The easiest way to browse the YAML manifests for the sample application and the modules in this workshop is using the file browser in the IDE:

![IDE files](./assets/ide-initial.webp)

Expanding the `eks-workshop` and then `base-application` items will allow you to browse the manifests that make up the initial state of the sample application:

![IDE files base](./assets/ide-base.webp)

The structure consists of a directory for each application component that was outlined in the **Sample application** section.

The `modules` directory contains sets of manifests that we will apply to the cluster throughout the subsequent lab exercises:

![IDE files modules](./assets/ide-modules.webp)

Before we do anything lets inspect the current Namespaces in our EKS cluster:

```bash
$ kubectl get namespaces
NAME                            STATUS   AGE
default                         Active   1h
kube-node-lease                 Active   1h
kube-public                     Active   1h
kube-system                     Active   1h
```

All of the entries listed are Namespaces for system components that were pre-installed for us. We'll ignore these by using [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to filter the Namespaces down to only those we've created:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
No resources found
```

The first thing we'll do is deploy the catalog component by itself. The manifests for this component can be found in `~/environment/eks-workshop/base-application/catalog`.

```bash
$ ls ~/environment/eks-workshop/base-application/catalog
configMap.yaml
deployment.yaml
kustomization.yaml
namespace.yaml
secrets.yaml
service-mysql.yaml
service.yaml
serviceAccount.yaml
statefulset-mysql.yaml
```

Let's examine the catalog Deployment manifest to see how it applies the concepts you learned:

::yaml{file="manifests/base-application/catalog/deployment.yaml" paths="spec.replicas,spec.template.metadata.labels,spec.template.spec.containers.0.image,spec.template.spec.containers.0.ports,spec.template.spec.containers.0.livenessProbe,spec.template.spec.containers.0.resources"}

Notice how this Deployment uses concepts from [Kubernetes Fundamentals](../../kubernetes-fundamentals):

1. **Replicas** - Runs a single replica (you learned about scaling in [Deployments](../../kubernetes-fundamentals/deployments))
2. **Labels** - Applies labels so Services can select these Pods
3. **Container Image** - Uses a pre-built container image from ECR Public
4. **Ports** - Exposes port 8080 for the HTTP API
5. **Health Checks** - Uses liveness probes (you learned about these in [Pods](../../kubernetes-fundamentals/pods))
6. **Resources** - Requests specific CPU and memory for scheduling

The Service manifest shows how to expose the application:

::yaml{file="manifests/base-application/catalog/service.yaml" paths="spec.ports,spec.selector"}

This Service demonstrates concepts from [Services](../../kubernetes-fundamentals/services):

1. **Port mapping** - Exposes port 80 externally, routes to port 8080 on Pods
2. **Selectors** - Uses labels to find the right Pods (matches the Deployment labels above)

Let's create the catalog component:

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog
namespace/catalog created
serviceaccount/catalog created
configmap/catalog created
secret/catalog-db created
service/catalog created
service/catalog-mysql created
deployment.apps/catalog created
statefulset.apps/catalog-mysql created
```

Now we'll see a new Namespace:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME      STATUS   AGE
catalog   Active   15s
```

Let's examine the Pods that were created:

```bash
$ kubectl get pod -n catalog
NAME                       READY   STATUS    RESTARTS      AGE
catalog-846479dcdd-fznf5   1/1     Running   2 (43s ago)   46s
catalog-mysql-0            1/1     Running   0             46s
```

Notice we have two Pods:
- **catalog-846479dcdd-fznf5** - The catalog API (managed by a Deployment)
- **catalog-mysql-0** - The MySQL database (managed by a StatefulSet)

This demonstrates the Pod concepts you learned in [Kubernetes Fundamentals](../../kubernetes-fundamentals/pods). If the catalog Pod shows `CrashLoopBackOff`, it's waiting to connect to the database - Kubernetes will keep restarting it until the connection succeeds.

```bash
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

Now that the Pods are running we can [check their logs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs), for example the catalog API:

:::tip
You can ["follow" the kubectl logs output](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) by using the '-f' option with the command. (Use CTRL-C to stop following the output)
:::

```bash
$ kubectl logs -n catalog deployment/catalog
```

## Applying Your Kubernetes Knowledge

Let's use the concepts you learned to interact with the application:

### Scaling (from Deployments)
Scale the catalog service horizontally:

```bash
$ kubectl scale -n catalog --replicas 3 deployment/catalog
deployment.apps/catalog scaled
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

### Services (from Services)
Examine the Services that were created:

```bash
$ kubectl get svc -n catalog
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     2m48s
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   2m48s
```

These are ClusterIP Services (internal only), just like you learned in [Services](../../kubernetes-fundamentals/services).

### Testing the Application
Use kubectl exec (from Pods) to test the API:

```bash
$ kubectl -n catalog exec -i \
  deployment/catalog -- curl catalog.catalog.svc/catalog/products | jq .
```

You should receive back a JSON payload with product information. 

## What You've Accomplished

Congratulations! You've successfully applied your Kubernetes knowledge to deploy a real microservice. You used:

- **Namespaces** - Organized resources logically
- **Deployments** - Managed the catalog API Pods
- **StatefulSets** - Managed the MySQL database
- **Services** - Enabled communication between components
- **ConfigMaps and Secrets** - Configured the application (check them with `kubectl get configmap,secret -n catalog`)

## Next Steps

Now let's deploy the complete application in [Full Deployment](./full-deployment) to see how all the microservices work together.
