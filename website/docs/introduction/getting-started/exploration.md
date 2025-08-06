---
title: Application exploration
sidebar_position: 50
---

# Application Exploration

Now that the complete retail application is deployed, let's explore it from both a user and operational perspective. This will help you understand how all the Kubernetes concepts work together in practice.

## Accessing the Application

### External Access
The UI service needs external access for users. Let's check how it's currently exposed:

```bash
$ kubectl get service -n ui
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   10.100.200.10   <none>        80/TCP    5m
```

Currently it's a ClusterIP service (internal only). Let's temporarily expose it for exploration:

```bash
$ kubectl port-forward -n ui service/ui 8080:80
```

Now you can access the application at http://localhost:8080

### Application Features
Explore the retail store application:

1. **Browse the catalog** - See products loaded from the catalog service
2. **Add items to cart** - Uses the cart service with DynamoDB
3. **Checkout process** - Orchestrated by the checkout service
4. **Order placement** - Handled by the orders service with PostgreSQL

## Understanding the Data Flow

### Service Communication
Let's trace how a user request flows through the system:

1. **User → UI Service** - Browser connects to UI
2. **UI → Catalog Service** - Fetches product information
3. **UI → Cart Service** - Manages shopping cart
4. **UI → Checkout Service** - Processes checkout
5. **Checkout → Orders Service** - Creates final order

### Database Interactions
Each service has its own database:

```bash
# Catalog service uses MySQL
$ kubectl get pods -n catalog
$ kubectl logs -n catalog deployment/catalog | grep -i mysql

# Cart service uses DynamoDB (simulated)
$ kubectl get pods -n carts
$ kubectl logs -n carts deployment/carts | grep -i dynamo

# Orders service uses PostgreSQL
$ kubectl get pods -n orders
$ kubectl logs -n orders deployment/orders | grep -i postgres
```

## Operational Exploration

### Resource Usage
Check resource consumption across the application:

```bash
$ kubectl top pods -l app.kubernetes.io/created-by=eks-workshop -A
```

### Health Status
Verify all services are healthy:

```bash
$ kubectl get pods -l app.kubernetes.io/created-by=eks-workshop -A
```

Look for:
- **Running** status
- **1/1** ready count
- Low restart count

### Service Dependencies
Understand service dependencies by checking configurations:

```bash
# UI service configuration shows which APIs it calls
$ kubectl get configmap -n ui ui -o yaml | grep -i url

# Checkout service configuration shows its dependencies
$ kubectl get configmap -n checkout checkout -o yaml
```

## Troubleshooting Practice

### Simulating Issues
Let's practice troubleshooting by simulating some common issues:

#### 1. Scale Down a Critical Service
```bash
$ kubectl scale -n catalog deployment/catalog --replicas=0
```

Now try to browse the catalog in the UI - you'll see errors.

Check the issue:
```bash
$ kubectl get pods -n catalog
$ kubectl logs -n ui deployment/ui
```

Fix it:
```bash
$ kubectl scale -n catalog deployment/catalog --replicas=1
```

#### 2. Configuration Issues
View current configuration:
```bash
$ kubectl get configmap -n ui ui -o yaml
```

#### 3. Network Connectivity
Test service-to-service communication:
```bash
$ kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh
# Inside the pod:
/ # nslookup catalog.catalog.svc.cluster.local
/ # wget -qO- http://catalog.catalog.svc.cluster.local/health
```

## Performance and Scaling

### Load Testing
Generate some load to see how the application behaves:

```bash
$ kubectl run load-test --image=busybox --rm -it --restart=Never -- sh
# Inside the pod, generate requests:
/ # for i in $(seq 1 100); do wget -qO- http://ui.ui.svc.cluster.local/ > /dev/null; done
```

### Monitoring Resource Usage
Watch resource usage during load:

```bash
$ kubectl top pods -l app.kubernetes.io/created-by=eks-workshop -A --watch
```

### Scaling Response
Scale services based on load:

```bash
$ kubectl scale -n ui deployment/ui --replicas=3
$ kubectl scale -n catalog deployment/catalog --replicas=2
```

## Configuration Deep Dive

### Environment Variables
See how configuration is injected:

```bash
$ kubectl exec -n ui deployment/ui -- env | grep -E "(CATALOG|CART|CHECKOUT|ORDER)"
```

### Mounted Configuration
Check mounted ConfigMaps and Secrets:

```bash
$ kubectl describe pod -n catalog -l app.kubernetes.io/name=catalog
```

Look for volume mounts and environment variables.

### Database Connections
Each service connects to its database using configuration:

```bash
# Catalog service database configuration
$ kubectl get secret -n catalog catalog-db -o yaml

# Orders service database configuration  
$ kubectl get secret -n orders orders-db -o yaml
```

## Security Exploration

### Service Accounts
Each service runs with its own service account:

```bash
$ kubectl get serviceaccounts -l app.kubernetes.io/created-by=eks-workshop -A
```

### Network Policies
Check if network policies are restricting communication:

```bash
$ kubectl get networkpolicies -A
```

### Secret Management
See how sensitive data is handled:

```bash
$ kubectl get secrets -l app.kubernetes.io/created-by=eks-workshop -A
```

## Application Insights

### Logging
Centralized logging from all services:

```bash
# View logs from all UI pods
$ kubectl logs -n ui -l app.kubernetes.io/name=ui --tail=50

# Follow logs in real-time
$ kubectl logs -n ui -l app.kubernetes.io/name=ui -f
```

### Health Checks
See how health checks are configured:

```bash
$ kubectl describe deployment -n catalog catalog
```

Look for liveness and readiness probe configurations.

### Service Discovery
Test DNS-based service discovery:

```bash
$ kubectl run dns-test --image=busybox --rm -it --restart=Never -- sh
# Test different service names:
/ # nslookup ui.ui.svc.cluster.local
/ # nslookup catalog.catalog.svc.cluster.local
/ # nslookup carts.carts.svc.cluster.local
```

## What You've Discovered

Through this exploration, you've seen:

1. **Real microservices architecture** - How services work together
2. **Service communication** - DNS-based discovery and HTTP APIs
3. **Data persistence** - Different databases for different needs
4. **Configuration management** - Environment-specific settings
5. **Health monitoring** - Probes and logging for observability
6. **Scaling patterns** - Independent service scaling
7. **Troubleshooting techniques** - Finding and fixing issues

## Next Steps

Now that you understand how the application works, you can:

1. **Learn Kustomize** - Understand the deployment tooling in [Kustomize](../kustomize)
2. **Explore advanced concepts** - Learn about StatefulSets, DaemonSets, and RBAC in [Advanced Concepts](../advanced-concepts)
3. **Continue to fundamentals** - Dive deeper into EKS-specific features in the [Fundamentals](/docs/fundamentals) module

The foundation you've built here will be essential for all subsequent workshop modules!