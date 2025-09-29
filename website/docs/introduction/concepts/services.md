---
title: Services
sidebar_position: 40
---

# Services - Enabling Network Communication

**Services** provide stable network endpoints for accessing pods. Since pods are ephemeral and can be created/destroyed frequently, services provide consistent DNS names and IP addresses for network communication.

## What Is a Service?

A Service:
- **Provides stable networking** - Consistent IP and DNS name
- **Load balances traffic** - Distributes requests across healthy pods
- **Enables service discovery** - Other components can find services by name
- **Abstracts pod locations** - Clients don't need to know individual pod IPs
- **Handles pod lifecycle** - Automatically updates as pods come and go

## Service Types

Kubernetes offers several service types for different use cases:

### ClusterIP (Default)
Exposes the service only within the cluster:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: catalog
```

### NodePort
Exposes the service on each node's IP at a static port:
```yaml
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Optional: Kubernetes assigns if not specified
```

### LoadBalancer
Exposes the service externally using a cloud provider's load balancer:
```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
```

### ExternalName
Maps the service to a DNS name:
```yaml
spec:
  type: ExternalName
  externalName: my.database.example.com
```

## Service Anatomy

Here's the catalog service from our retail store:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog
  namespace: catalog
  labels:
    app.kubernetes.io/name: catalog
    app.kubernetes.io/component: service
spec:
  type: ClusterIP
  ports:
  - port: 80          # Port the service exposes
    targetPort: http  # Port on the pod (can be name or number)
    protocol: TCP
    name: http
  selector:           # Which pods this service routes to
    app.kubernetes.io/name: catalog
    app.kubernetes.io/component: service
```

## Key Service Concepts

### 1. Selectors
Services use label selectors to find pods:
```yaml
spec:
  selector:
    app.kubernetes.io/name: catalog
    app.kubernetes.io/component: service
```

Any pod with these labels will receive traffic from this service.

### 2. Port Mapping
Services can map different ports:
```yaml
spec:
  ports:
  - port: 80        # Service port (what clients connect to)
    targetPort: 8080 # Pod port (where the application listens)
```

### 3. Endpoints
Kubernetes automatically creates endpoints for services:
```bash
$ kubectl get endpoints -n catalog catalog
```

This shows the actual pod IPs that the service routes to.

## Exploring Services in Our Application

Let's examine the services in our retail store:

```bash
# See all services
$ kubectl get services -A -l app.kubernetes.io/created-by=eks-workshop

# Focus on catalog service
$ kubectl get service -n catalog
```

You should see:
```
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     15m
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   15m
```

### Service Details
Get detailed information:
```bash
$ kubectl describe service -n catalog catalog
```

This shows:
- **Type** - ClusterIP, NodePort, LoadBalancer, etc.
- **IP addresses** - Cluster IP and external IP (if applicable)
- **Ports** - Port mappings
- **Endpoints** - Pod IPs that receive traffic
- **Session Affinity** - Whether requests stick to the same pod

### Service Endpoints
Check which pods the service routes to:
```bash
$ kubectl get endpoints -n catalog catalog
```

## Service Discovery

Services enable automatic service discovery through DNS:

### DNS Names
Services get DNS names in the format:
```
<service-name>.<namespace>.svc.cluster.local
```

Examples from our application:
- `catalog.catalog.svc.cluster.local`
- `ui.ui.svc.cluster.local`
- `carts.carts.svc.cluster.local`

### Short Names
Within the same namespace, you can use short names:
```bash
# From a pod in the catalog namespace
$ curl http://catalog-mysql:3306

# From a pod in a different namespace
$ curl http://catalog-mysql.catalog.svc.cluster.local:3306
```

### Testing Service Discovery
Let's test DNS resolution:
```bash
# Create a test pod
$ kubectl run dns-test --image=busybox --rm -it --restart=Never -- sh

# Inside the pod, test DNS
/ # nslookup catalog.catalog.svc.cluster.local
/ # nslookup ui.ui.svc.cluster.local
/ # exit
```

## Load Balancing

Services automatically load balance traffic across healthy pods:

### Round Robin (Default)
Traffic is distributed evenly across all healthy pods.

### Session Affinity
Route requests from the same client to the same pod:
```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

### Testing Load Balancing
Scale a deployment and test load balancing:
```bash
# Scale catalog to 3 replicas
$ kubectl scale deployment -n catalog catalog --replicas=3

# Test load balancing
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh
/ # for i in $(seq 1 10); do curl -s http://catalog.catalog.svc.cluster.local/health | grep hostname; done
```

## Service Communication Patterns

### Synchronous Communication
Direct HTTP/gRPC calls between services:
```bash
# UI service calls catalog service
curl http://catalog.catalog.svc.cluster.local/products
```

### Asynchronous Communication
Using message queues or event streams (not shown in our basic example).

### Database Access
Services can expose databases:
```yaml
# MySQL service for catalog
apiVersion: v1
kind: Service
metadata:
  name: catalog-mysql
spec:
  ports:
  - port: 3306
  selector:
    app.kubernetes.io/name: catalog-mysql
```

## Working with Services

### Creating Services
```bash
# Imperative way
$ kubectl expose deployment my-app --port=80 --target-port=8080

# Declarative way (recommended)
$ kubectl apply -f service.yaml
```

### Testing Services
```bash
# Test from within the cluster
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl http://my-service

# Port forward to test locally
$ kubectl port-forward service/my-service 8080:80
```

### Updating Services
```bash
# Edit service directly
$ kubectl edit service my-service

# Update selector
$ kubectl patch service my-service -p '{"spec":{"selector":{"version":"v2"}}}'
```

## Service Mesh Integration

Services work well with service mesh technologies:

### Istio
Provides advanced traffic management:
- **Traffic splitting** - A/B testing and canary deployments
- **Circuit breaking** - Fault tolerance
- **Mutual TLS** - Automatic encryption
- **Observability** - Detailed metrics and tracing

### Linkerd
Lightweight service mesh:
- **Automatic TLS** - Secure communication
- **Load balancing** - Advanced algorithms
- **Retries and timeouts** - Resilience patterns

## Best Practices

### 1. Use Meaningful Names
Choose service names that reflect their purpose:
```yaml
metadata:
  name: catalog-api  # Clear and descriptive
```

### 2. Label Services
Use consistent labels:
```yaml
metadata:
  labels:
    app.kubernetes.io/name: catalog
    app.kubernetes.io/component: service
    app.kubernetes.io/version: "1.2.1"
```

### 3. Health Checks
Ensure pods have health checks so services only route to healthy pods:
```yaml
# In the deployment
readinessProbe:
  httpGet:
    path: /health
    port: 8080
```

### 4. Port Naming
Name your ports for clarity:
```yaml
spec:
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: metrics
    port: 9090
    targetPort: metrics
```

### 5. Resource Limits
Set appropriate resource limits on pods so services can load balance effectively.

## Troubleshooting Services

### Common Issues

**Service Not Accessible:**
```bash
$ kubectl get service my-service
$ kubectl get endpoints my-service
# Check if endpoints exist
```

**No Endpoints:**
```bash
$ kubectl get pods -l app=my-app
$ kubectl describe service my-service
# Verify selector matches pod labels
```

**DNS Not Working:**
```bash
$ kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup my-service
# Test DNS resolution
```

### Debug Commands
```bash
# Check service configuration
$ kubectl describe service my-service

# Test connectivity
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl http://my-service

# Check endpoints
$ kubectl get endpoints my-service -o yaml
```

## Service vs Ingress

### Services
- **Internal communication** - Between pods in the cluster
- **Load balancing** - Across pod replicas
- **Service discovery** - DNS-based discovery

### Ingress
- **External access** - From outside the cluster
- **HTTP/HTTPS routing** - Path and host-based routing
- **TLS termination** - SSL certificate management

Services and Ingress work together - Ingress routes external traffic to Services.

## Key Takeaways

- Services provide stable network endpoints for pods
- They enable service discovery through DNS
- ClusterIP services are for internal communication
- LoadBalancer services provide external access
- Services automatically load balance across healthy pods
- Use meaningful names and labels for organization

## Next Steps

Services handle networking, but applications also need configuration data. Let's learn about [ConfigMaps & Secrets](./configuration) - how Kubernetes manages application configuration and sensitive data.