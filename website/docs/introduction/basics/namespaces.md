---
title: Namespaces
sidebar_position: 10
---

# Namespaces

**Namespaces** provide a way to organize and isolate resources within a single Kubernetes cluster. Think on them as virtual clusters within your physical cluster - they help you separate different applications, environments, or teams while sharing the same underlying infrastructure.

Namespaces provide:
- **Organization:** Group related resources together (like all components of an application)
- **Isolation:** Prevent resource conflicts between different applications or teams
- **Resource Management:** Apply quotas and limits to specific groups of resources
- **Access control:** Control who can access which resources

In this lab, you'll learn about namespaces by creating them and deploying parts of our retail store application.

### Default Namespaces

Every Kubernetes cluster starts with several built-in namespaces:

- **default** - Where resources go if you don't specify a namespace
- **kube-system** - System components like DNS and networking
- **kube-public** - Publicly readable resources
- **kube-node-lease** - Node heartbeat information

```bash
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   1h
kube-node-lease   Active   1h
kube-public       Active   1h
kube-system       Active   1h
```

### Creating Your First Namespace
Let's create a namespace for our retail store's UI component:

::yaml{file="manifests/base-application/ui/namespace.yaml" paths="kind,metadata.name,metadata.labels" title="namespace.yaml"}

1. `kind: Namespace`: Tells Kubernetes what type of resource to create.
2. `metadata.name`: Unique identifier for this namespace within the cluster.
3. `metadata.labels`: Key-value pairs that organize and categorize resources.

Apply the configuration file using `kubectl`
```bash
$ kubectl apply -f ~/environment/eks-workshop/base-application/ui/namespace.yaml
```

Let's inspect the `ui` namespace object:
```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

### Using Namespaces
When working with resources, you can specify the namespace in two ways:

**Using the `-n` flag:**
```bash
$ kubectl get all -n ui
```

**Using the `--namespace` flag:**
```bash
$ kubectl get all --namespace ui
```

### Namespaces in this workshop
Throughout this workshop, our retail store application uses several namespaces to organize its microservices:

- `ui` - Frontend user interface
- `catalog` - Product catalog service
- `carts` - Shopping cart service
- `checkout` - Order processing service
- `orders` - Order management service

You'll see commands like this throughout the labs:
```bash
$ kubectl get pods -n ui
$ kubectl get secrets -n catalog
```

This organization makes it easy to:
* See which components belong to which service
* Apply configurations to specific services
* Troubleshoot issues within a particular service

## Key Points to Remember
* Namespaces organize and separate resources
* Names must be unique within a namespace
* Most resources are namespaced, some are cluster-wide
* Default namespace is used when none specified
* Enable resource quotas and access control

## Next Steps

Now that you understand how namespaces organize resources, let's learn about [Pods](./pods) - the smallest deployable units that actually run your applications.
