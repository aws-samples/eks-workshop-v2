---
title: Namespaces
sidebar_position: 10
sidebar_custom_props: { "module": true }
---

# Namespaces

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/namespaces
```

:::

**Namespaces** provide a way to organize and isolate resources within a single Kubernetes cluster. Think on them as virtual clusters inside your physical cluster - they help you separate different applications, environments, or teams while sharing the same underlying infrastructure.

You can think of namespaces like folders on your computer — they let you group related files (resources) without mixing them up.

Namespaces provide:
- **Organization:** Group related resources together (like all components of an application)
- **Isolation:** Prevent resource conflicts between different applications or teams
- **Resource Management:** Apply quotas and limits to specific groups of resources
- **Access control:** Use Kubernetes permissions (called RBAC — Role-Based Access Control) to decide who can access or change resources.

In this section, you'll explore how namespaces organize resources by working with the different components of our retail store application.

### Default Namespaces
Every Kubernetes cluster starts with several built-in namespaces. These are created automatically when a cluster is provisioned:

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

You can also create namespaces directly using the `kubectl create` command. Let's create a namespace for our `catalog` service and add labels (labels are optional but helpful for organization):

```bash
$ kubectl create namespace catalog
$ kubectl label namespace catalog app.kubernetes.io/created-by=eks-workshop
```

Let's inspect both namespaces:
```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

The `-l` flag stands for "label selector" and filters resources based on their labels. In this case, we're only showing namespaces that have the label `app.kubernetes.io/created-by=eks-workshop`. This is useful for finding resources created by this workshop among all the namespaces in your cluster.

Describe namespace
```bash
$ kubectl describe namespace ui
Name:         ui
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=ui
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
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


Tip: You can also see resources across all namespaces using the -A flag:

```bash
$ kubectl get pods -A
```

### Namespaces in this workshop
In this workshop, namespaces help us separate the different microservices that make up our sample retail store application.

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
* Some resources (like Nodes and PersistentVolumes) are not namespaced and exist at the cluster level.
* Default namespace is used when none specified
* Enable resource quotas and access control