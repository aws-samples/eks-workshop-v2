---
title: Full deployment
sidebar_position: 40
---

# Full Application Deployment

Now let's deploy the complete retail application to see how all the microservices work together. This will demonstrate how the Kubernetes concepts you learned scale to real applications.

## Understanding the Complete Deployment

The full application uses a master kustomization file that references all components:

```file
manifests/base-application/kustomization.yaml
```

This demonstrates **declarative configuration** - we describe what we want (all components deployed) and Kubernetes makes it happen.

:::tip
Notice the catalog API is included even though we already deployed it. Because Kubernetes uses declarative management, applying the same manifests again will result in no changes - Kubernetes recognizes the resources already exist.
:::

## Deploy All Components

Apply the complete application:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

Wait for all components to be ready:

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

## Exploring the Deployed Application

### Namespaces
Each microservice runs in its own namespace for organization:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
ui         Active   62s
```

This demonstrates the **namespace** concept for logical separation.

### Deployments
View all the Deployments across namespaces:

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                READY   UP-TO-DATE   AVAILABLE   AGE
carts       carts               1/1     1            1           90s
carts       carts-dynamodb      1/1     1            1           90s
catalog     catalog             1/1     1            1           7m46s
checkout    checkout            1/1     1            1           90s
checkout    checkout-redis      1/1     1            1           90s
orders      orders              1/1     1            1           90s
orders      orders-postgresql   1/1     1            1           90s
ui          ui                  1/1     1            1           90s
```

Notice how each microservice and its database are managed by separate Deployments.

### Services
Each component has Services for communication:

```bash
$ kubectl get services -l app.kubernetes.io/created-by=eks-workshop -A
```

This shows the **service mesh** - how all components can communicate with each other.

## Understanding the Architecture in Practice

### Microservice Communication
Let's see how services communicate. The UI service calls other APIs:

```bash
$ kubectl get configmap -n ui ui -o yaml
```

Look for environment variables that contain URLs of other services - this shows **service discovery** in action.

### Configuration Management
Each service has its own configuration:

```bash
$ kubectl get configmaps -l app.kubernetes.io/created-by=eks-workshop -A
$ kubectl get secrets -l app.kubernetes.io/created-by=eks-workshop -A
```

This demonstrates **configuration separation** - each service manages its own settings.

### Database Patterns
Notice the database components:

- **catalog-mysql** - Traditional relational database
- **carts-dynamodb** - NoSQL database (simulated)
- **orders-postgresql** - Another relational database
- **checkout-redis** - In-memory cache

Each uses **StatefulSets** for persistent storage, different from the stateless application **Deployments**.

## Testing the Complete Application

### Internal Communication
Test service-to-service communication:

```bash
$ kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh
# Inside the pod, test service discovery:
/ # nslookup catalog.catalog.svc.cluster.local
/ # nslookup ui.ui.svc.cluster.local
```

### Application Health
Check that all services are healthy:

```bash
$ kubectl get pods -l app.kubernetes.io/created-by=eks-workshop -A
```

All pods should show `Running` status and `1/1` ready.

## Scaling the Application

Now that you understand the full application, let's apply scaling concepts:

### Scale Individual Services
```bash
$ kubectl scale -n ui deployment/ui --replicas=3
$ kubectl scale -n catalog deployment/catalog --replicas=2
$ kubectl scale -n carts deployment/carts --replicas=2
```

### Verify Scaling
```bash
$ kubectl get pods -l app.kubernetes.io/created-by=eks-workshop -A
```

Notice how each service can scale independently - this is a key microservices benefit.

## Real-World Patterns Demonstrated

This deployment shows several important patterns:

### 1. Microservices Architecture
- Each service has a single responsibility
- Services communicate via well-defined APIs
- Independent scaling and deployment

### 2. Data Separation
- Each service owns its data
- Different database technologies for different needs
- No shared databases between services

### 3. Configuration Management
- Environment-specific settings in ConfigMaps
- Sensitive data in Secrets
- Configuration injected at runtime

### 4. Service Discovery
- Services find each other using DNS names
- No hard-coded IP addresses
- Kubernetes handles service registration

### 5. Health Monitoring
- Liveness probes ensure containers are healthy
- Readiness probes control traffic routing
- Kubernetes automatically restarts failed containers

## What You've Learned

By deploying this complete application, you've seen how Kubernetes concepts work together:

- **Pods** - Run your application containers
- **Deployments** - Manage Pod lifecycle and scaling
- **Services** - Enable communication between components
- **ConfigMaps/Secrets** - Manage configuration and sensitive data
- **Namespaces** - Organize and isolate resources

## Next Steps

The application is now fully deployed and ready for exploration! You can:

1. **Explore the application** in [Application Exploration](./exploration) to understand how it works from a user perspective
2. **Learn about Kustomize** in the [Kustomize module](../kustomize) to understand the deployment tooling
3. **Continue to advanced topics** in the [Advanced Concepts](../advanced-concepts) section

:::tip
This application will be used throughout the workshop, so understanding its structure will help in later modules covering security, networking, observability, and more.
:::