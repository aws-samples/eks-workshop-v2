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

#### Why Services are important:
Pods can come and go, so clients cannot reliably connect to them directly. Services:
- **Provide stable networking:** IP and DNS names remain same even if pods change.
- **Offer load balancing:** Automatically distribute requests across healthy pods
- **Enable service discovery:** Other components can reach the service by name
- **Provide pod abstraction:** Clients don’t need to know individual pod IPs
- **Handle automatic updates:** Adjust endpoints as pods are created or destroyed

In this lab, you'll create a service for the catalog component of our retail store and explore how services enable communication between pods.

### Service Types

Kubernetes provides different service types for various use cases:

| Type | Purpose | Access |
|------|---------|--------|
| **ClusterIP** | Internal cluster communication | Cluster-only |
| **NodePort** | External access via node ports | External |
| **LoadBalancer** | External access via cloud load balancer | External |
| **ExternalName** | Map to external DNS name | External |

:::info
A dedicated lab on **LoadBalancer services** is available later in this workshop. You will learn how to expose services externally using a cloud load balancer there.
:::

### Creating a Service

Let's examine the UI service from our retail store:

::yaml{file="manifests/base-application/ui/service.yaml" paths="kind,metadata.name,spec.type,spec.ports,spec.selector" title="service.yaml"}

1. `kind: Service`: Creates a Service resource
2. `metadata.name`: Name of the service (ui)
3. `spec.type`: Service type (ClusterIP for internal access)
4. `spec.ports`: Port mapping from service to pods
5. `spec.selector`: Selects which pods receive traffic

Deploy the service:
```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/ui/
```

### How Services Connect to Pods

Services don't directly know about specific pods. Instead, they use **label selectors** to dynamically find pods that should receive traffic. This creates a flexible, loosely-coupled relationship.

**Here's how it works:**

1. **Pods have labels** - Key-value pairs that describe the pod
2. **Services have selectors** - Criteria that match pod labels  
3. **Kubernetes automatically connects them** - Any pod matching the selector becomes an endpoint

Let's see this in action with our UI service:

```bash
# Check the service selector
$ kubectl get service -n ui ui -o yaml | grep -A 3 selector:
```

You'll see something like:
```yaml
selector:
  app.kubernetes.io/component: service
  app.kubernetes.io/instance: ui
  app.kubernetes.io/name: ui
```

Now check which pods have matching labels:
```bash
# Look for pods with matching labels
$ kubectl get pods -n ui -l app.kubernetes.io/component=service --show-labels
```

You'll see the UI pods have labels that match the service selector. This is how the service knows which pods to send traffic to.

**The relationship is dynamic:**
- When new pods start with matching labels, they automatically become service endpoints
- When pods are deleted, they're automatically removed from the service
- If you change a pod's labels, it can be added or removed from services

This label-based system means:
- **Services work with any workload controller** (Deployments, StatefulSets, etc.)
- **Pods can belong to multiple services** if they match different selectors
- **Services automatically adapt** as pods scale up or down

### Exploring Your Service

Check service status:
```bash
$ kubectl get service -n ui
```

You'll see output showing the service details:
```
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.83.84    <none>        80/TCP    15m
```

View service endpoints (the actual pod IPs):
```bash
$ kubectl get endpoints -n ui ui
```

This shows which pods receive traffic:
```
NAME   ENDPOINTS           AGE
ui     10.42.1.15:8080     15m
```

Get detailed service information:
```bash
$ kubectl describe service -n ui ui
```

### Service Discovery

Services enable automatic service discovery through DNS names:

**Full DNS name format:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Examples from our retail store:**
- `ui.ui.svc.cluster.local`
- `catalog.catalog.svc.cluster.local`
- `carts.carts.svc.cluster.local`

**Short names within the same namespace:**
```
# From a pod in the ui namespace
curl http://ui:80

# From a different namespace, use the full name
curl http://ui.ui.svc.cluster.local:80
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
$ nslookup ui.ui.svc.cluster.local

# Test HTTP communication (shows pod info)
$ curl http://ui.ui.svc.cluster.local/actuator/info

# Exit the test pod
$ exit
```

### Load Balancing

Services automatically distribute traffic across all healthy pods that match their selector:

**Scale the UI deployment to see load balancing:**
```bash
$ kubectl scale deployment -n ui ui --replicas=3
```

**Watch how the service endpoints update:**
```bash
$ kubectl get endpoints -n ui ui
```

You'll now see multiple pod IPs listed as endpoints - the service automatically discovered the new pods because they have matching labels.

**Test load balancing:**
```bash
$ kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the pod, make multiple requests
$ for i in $(seq 1 5); do curl -s http://ui.ui.svc.cluster.local/actuator/info ; sleep 1s; echo ""; done

# Exit the test pod
$ exit
```

You'll see requests distributed across different pod hostnames, demonstrating how the service load balances across all matching pods.

## Key Points to Remember

* Services provide stable network endpoints for ephemeral pods
* ClusterIP services enable internal cluster communication
* Services use label selectors to find target pods
* DNS names follow the pattern: service.namespace.svc.cluster.local
* Services automatically load balance traffic across healthy pods
* Use port forwarding to test services locally