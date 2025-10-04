---
title: Pods
sidebar_position: 20
sidebar_custom_props: { "module": true }
---

# Pods

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/pods
```

:::

**Pods** are the smallest deployable units in Kubernetes. A pod represents one or more containers that share storage, network, and configuration settings for how they should run together.

Pods provide:
- **Container grouping:** Usually, a pod runs a single container, but it can include multiple tightly coupled containers that need to share data or communicate over localhost.
- **Shared networking:** All containers in a pod share the same IP address
- **Shared storage:** Containers can share volumes within the pod
- **Lifecycle management:** Containers in a pod live and die together
- **Ephemeral nature:** Pods can be created, destroyed, and recreated

In this lab, you'll learn about pods by creating a simple example pod and exploring its properties.

### Creating Your First Pod

Let's create a simple pod to understand how they work. The manifest defines a simple pod running the retail store UI container.

::yaml{file="manifests/modules/introduction/basics/pods/ui-pod.yaml" paths="kind,metadata.name,metadata.namespace,spec.containers,spec.containers.0.name,spec.containers.0.image,spec.containers.0.ports,spec.containers.0.env,spec.containers.0.resources" title="ui-pod.yaml"}

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
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
```

Kubernetes will create the pod in the `ui` namespace and start pulling the container image.

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

You’ll see the UI container starting up. Some error messages about missing backend services may appear — that’s expected since other components (catalog, cart, checkout) aren’t deployed yet.

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

:::info
Port forwarding temporarily connects your local port to a port inside the pod, allowing you to access the application directly from your laptop.
:::

In the Workshop IDE, a popup appears to view all forwarded ports. Click to open applicaiton URL in the browser.

Alternatively, open another terminal and test:
```bash
$ curl localhost:8080
```

In the browser, You'll notice the page is not rendered appropriately because catalog, cart, and other services are not deployed in the cluster. We will build the necessary configurations in the following labs.

### Pod Lifecycle

Pods have well-defined lifecycle phases that reflect their current state in the cluster.
- **Pending** - Pod is being scheduled and containers are starting
- **Running** - At least one container is running
- **Succeeded** - All containers have completed successfully
- **Failed** - At least one container has failed
- **Unknown** - Pod state cannot be determined

Kubernetes controllers continuously monitor pod states and take action (like restarting failed containers or recreating pods) to maintain desired application health.

## Key Points to Remember

* Pods are the smallest deployable units in Kubernetes
* Usually contain one container, but can contain multiple
* Share network and storage within the pod
* Are ephemeral - they come and go
* Typically managed by higher-level controllers like Deployments
* In real-world scenarios, you rarely create pods directly — instead, you use higher-level resources like Deployments, ReplicaSets, or Jobs to manage them.