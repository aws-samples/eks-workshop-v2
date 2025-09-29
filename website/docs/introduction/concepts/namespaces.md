---
title: Namespaces
sidebar_position: 10
---

# Namespaces - Organizing Your Cluster

**Namespaces** are Kubernetes' way of organizing and isolating resources within a cluster. Think of them as virtual clusters within your physical cluster - like having separate folders for different projects on you computer.

Namespaces provide:
- **Logical separation** of resources
- **Scope for names** - you can have multiple resources with the same name in different namespaces
- **Resource quotas** - limit resource usage per namespace
- **Access control** - apply different permissions to different namespaces

In this lab, you'll learn about namespaces by creating them and deploying parts of our retail store application.

### Understanding Default Namespaces

Let's start by exploring what namespaces already exists:

```bash
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   1h
kube-node-lease   Active   1h
kube-public       Active   1h
kube-system       Active   1h
```
Every Kubernetes cluster starts with several system namespaces:

- **default** - Where resources go if you don't specify a namespace
- **kube-system** - System components like DNS and networking
- **kube-public** - Publicly readable resources
- **kube-node-lease** - Node heartbeat information

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



This separation provides several benefits:

### 1. Organization
Each microservice's resources are grouped together:
```bash
# All catalog resources
$ kubectl get all -n catalog

# All UI resources  
$ kubectl get all -n ui
```

### 2. Isolation
Services in different namespaces are isolated by default:
- A pod in the `ui` namespace can't directly access a pod in `catalog` without explicit networking
- Resource names can be reused across namespaces

### 3. Resource Management
You can apply resource limits per namespace:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: catalog
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```

## Working with Namespaces

### Creating Namespaces
```bash
# Imperative way
$ kubectl create namespace my-app

# Declarative way (YAML)
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    app: my-application
EOF
```

### Specifying Namespaces
Most kubectl commands accept a namespace flag:
```bash
# Get pods in specific namespace
$ kubectl get pods -n catalog

# Get pods in all namespaces
$ kubectl get pods -A

# Set default namespace for current context
$ kubectl config set-context --current --namespace=catalog
```

### Namespace in YAML
Resources specify their namespace in metadata:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: catalog  # This pod goes in the catalog namespace
spec:
  containers:
  - name: app
    image: nginx
```

## DNS and Service Discovery

Namespaces affect how services find each other. Services get DNS names like:
```
<service-name>.<namespace>.svc.cluster.local
```

Examples from our application:
- `catalog.catalog.svc.cluster.local` - Catalog service
- `ui.ui.svc.cluster.local` - UI service
- `carts.carts.svc.cluster.local` - Cart service

Within the same namespace, you can use short names:
```bash
# From a pod in the catalog namespace
$ curl http://catalog-mysql:3306  # Short name works

# From a pod in a different namespace
$ curl http://catalog-mysql.catalog.svc.cluster.local:3306  # Full name required
```

## Best Practices

### 1. Use Meaningful Names
Choose namespace names that reflect their purpose:
- `production`, `staging`, `development` for environments
- `frontend`, `backend`, `database` for application tiers
- `team-a`, `team-b` for team isolation

### 2. Apply Labels
Use labels for grouping and selection:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: catalog
  labels:
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/component: microservice
    environment: production
```

### 3. Set Resource Quotas
Prevent resource exhaustion:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: catalog
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 8Gi
```

### 4. Use Network Policies
Control traffic between namespaces:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: catalog
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Exploring Our Application Namespaces

Let's examine what's in each namespace:

```bash
# See all resources in catalog namespace
$ kubectl get all -n catalog

# Check namespace labels
$ kubectl get namespace catalog --show-labels

# See which namespaces have our application
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

## Common Operations

### Deleting Resources by Namespace
```bash
# Delete all resources in a namespace
$ kubectl delete all --all -n my-namespace

# Delete the namespace itself (deletes all resources in it)
$ kubectl delete namespace my-namespace
```

### Switching Default Namespace
```bash
# Set default namespace for current context
$ kubectl config set-context --current --namespace=catalog

# Verify current namespace
$ kubectl config view --minify | grep namespace
```

## Key Takeaways

- Namespaces provide logical separation and organization
- Each microservice in our application has its own namespace
- DNS names include the namespace: `service.namespace.svc.cluster.local`
- Use labels to group and select namespaces
- Resource quotas and network policies can be applied per namespace

## Next Steps

Now that you understand how namespaces organize resources, let's learn about [Pods](./pods) - the smallest deployable units that actually run your applications.