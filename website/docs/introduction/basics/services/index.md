---
title: Services
sidebar_position: 40
sidebar_custom_props: { "module": true }
---

# Services

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/services
```

:::

**Services** provide stable network endpoints for accessing pods. Since pods are ephemeral and can be created/destroyed frequently, services give you consistent DNS names and IP addresses for reliable communication.

Services provide:
- **Stable networking:** Consistent IP and DNS name that doesn't change
- **Load balancing:** Distributes requests across healthy pods automatically
- **Service discovery:** Other components can find services by name
- **Pod abstraction:** Clients don't need to know individual pod IPs
- **Automatic updates:** Handles pod lifecycle changes seamlessly

In this lab, you'll learn about services by creating one for our retail store's catalog component and exploring how services enable communication between pods.

### Service Types

Kubernetes provides different service types for various use cases:

| Type | Purpose | Access |
|------|---------|--------|
| **ClusterIP** | Internal cluster communication | Cluster-only |
| **NodePort** | External access via node ports | External |
| **LoadBalancer** | External access via cloud load balancer | External |
| **ExternalName** | Map to external DNS name | External |

### Creating Your First Service

Let's examine the catalog service from our retail store:

::yaml{file="manifests/base-application/catalog/service.yaml" paths="kind,metadata.name,spec.type,spec.ports,spec.selector" title="service.yaml"}

1. `kind: Service`: Creates a Service resource
2. `metadata.name`: Name of the service (catalog)
3. `spec.type`: Service type (ClusterIP for internal access)
4. `spec.ports`: Port mapping from service to pods
5. `spec.selector`: Which pods this service routes traffic to

Deploy the service:
```bash
$ kubectl apply -f ~/environment/eks-workshop/manifests/base-application/catalog/
```

### Exploring Your Service

Check service status:
```bash
$ kubectl get service -n catalog
```

You'll see output showing the service details:
```
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     15m
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   15m
```

View service endpoints (the actual pod IPs):
```bash
$ kubectl get endpoints -n catalog catalog
```

This shows which pods receive traffic:
```
NAME      ENDPOINTS           AGE
catalog   10.42.1.15:8080     15m
```

Get detailed service information:
```bash
$ kubectl describe service -n catalog catalog
```

### Service Discovery

Services enable automatic service discovery through DNS names:

**Full DNS name format:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Examples from our retail store:**
- `catalog.catalog.svc.cluster.local`
- `ui.ui.svc.cluster.local`
- `carts.carts.svc.cluster.local`

**Short names within the same namespace:**
```bash
# From a pod in the catalog namespace
curl http://catalog-mysql:3306

# From a different namespace, use the full name
curl http://catalog-mysql.catalog.svc.cluster.local:3306
```

### Testing Service Communication

Let's test service discovery and communication:

```bash
# Create a test pod
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh
```

Inside the test pod:
```bash
# Test DNS resolution
$ nslookup catalog.catalog.svc.cluster.local

# Test HTTP communication
$ curl http://catalog.catalog.svc.cluster.local/products

# Exit the test pod
$ exit
```

### Load Balancing

Services automatically distribute traffic across healthy pods:

**Scale the catalog service to see load balancing:**
```bash
$ kubectl scale deployment -n catalog catalog --replicas=3
```

**Test load balancing:**
```bash
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the pod, make multiple requests
$ for i in $(seq 1 5); do curl -s http://catalog.catalog.svc.cluster.local/actuator/info | grep hostname; done
```

You'll see requests distributed across different pod hostnames.

### Port Forwarding for Testing

Access services locally for testing:

```bash
# Forward service port to your local machine
$ kubectl port-forward -n catalog service/catalog 8080:80

# In another terminal, test locally
$ curl http://localhost:8080/products
```

:::info
Port forwarding temporarily connects your local port to a service, allowing you to access the application directly from your laptop for testing purposes.
:::

## Key Points to Remember

* Services provide stable network endpoints for ephemeral pods
* ClusterIP services enable internal cluster communication
* Services use label selectors to find target pods
* DNS names follow the pattern: service.namespace.svc.cluster.local
* Services automatically load balance traffic across healthy pods
* Use port forwarding to test services locally