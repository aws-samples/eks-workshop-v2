---
title: Pods
sidebar_position: 20
---

# Pods

**Pods** are the smallest deployable units in Kubernetes. They represent a group of one or more containers that share storage, network, and a specification for how to run.

Pods provide:
- **Container grouping:** Usually one container per pod, but can contain multiple
- **Shared networking:** All containers in a pod share the same IP address
- **Shared storage:** Containers can share volumes within the pod
- **Lifecycle management:** Containers in a pod live and die together
- **Ephemeral nature:** Pods can be created, destroyed, and recreated

In this lab, you'll learn about pods by creating a simple example pod and exploring its properties.

### Creating Your First Pod

Let's create a simple pod to understand how they work:

::yaml{file="manifests/modules/introduction/basics/ui-pod.yaml" paths="kind,metadata.name,metadata.namespace,spec.containers,spec.containers.0.name,spec.containers.0.image,spec.containers.0.ports,spec.containers.0.env,spec.containers.0.resources" title="ui-pod.yaml"}

1. `kind: Pod`: Tells Kubernetes what type of resource to create
2. `metadata.name`: Unique identifier for this pod within the namespace
3. `metadata.namespace`: Which namespace the pod belongs to (ui namespace)
4. `spec.containers`: Array defining what containers run in the pod
5. `spec.containers.0.name`: Name of the first container (ui)
6. `spec.containers.0.image`: Container image from ECR Public registry
7. `spec.containers.0.ports`: Network ports the container exposes
8. `spec.containers.0.env`: Environment variables for the container
9. `spec.containers.0.resources`: CPU and memory allocation settings

Apply the pod configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/ui-pod.yaml
```

### Exploring Your Pod

Now let's examine the pod we just created:

```bash
$ kubectl get pods -n ui
```

You should see output like:
```
NAME     READY   STATUS    RESTARTS   AGE
ui-pod   1/1     Running   0          30s
```

Get detailed information about the pod:
```bash
$ kubectl describe pod -n ui ui-pod
```

This shows:
- **Container specifications** - Image, ports, environment variables
- **Resource usage** - CPU and memory requests/limits
- **Events** - What happened during pod creation
- **Status** - Current state and health

View the pod's logs:
```bash
$ kubectl logs -n ui ui-pod
```

You'll see the Java application starting up and some error messages about missing backend services - this is expected since we haven't deployed the other components yet.

Execute a command inside the pod:
```bash
$ kubectl exec -n ui ui-pod -- curl localhost:8080
```

This should return the retail store UI HTML page.

### Accessing Your Pod

You can access the pod from your local machine using port forwarding:
```bash
$ kubectl port-forward -n ui ui-pod 8080:8080
```

Then open another terminal and test:
```bash
$ curl localhost:8080
```

You can also open http://localhost:8080 in your browser to see the retail store UI. You'll notice error messages for the catalog, cart, and other services - this is expected since we're only running the UI pod without the backend services.

### Cleaning Up

When you're done exploring, delete the pod:
```bash
$ kubectl delete pod -n ui ui-pod
```

### Pod Lifecycle

Pods go through several phases:
- **Pending** - Pod is being scheduled and containers are starting
- **Running** - At least one container is running
- **Succeeded** - All containers have completed successfully
- **Failed** - At least one container has failed
- **Unknown** - Pod state cannot be determined

## Key Points to Remember

* Pods are the smallest deployable units in Kubernetes
* Usually contain one container, but can contain multiple
* Share network and storage within the pod
* Are ephemeral - they come and go
* Typically managed by higher-level controllers like Deployments

## Next Steps

Pods are typically not created directly. Instead, they're managed by higher-level controllers like Deployments, which handle scaling, updates, and pod lifecycle management.