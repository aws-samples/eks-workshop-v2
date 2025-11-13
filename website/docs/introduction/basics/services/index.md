---
title: Services
sidebar_position: 40
---

# Services

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
```bash hook=ready
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/services/
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
$ kubectl get service -n ui ui -o jsonpath='{.spec.selector}' | jq
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

Now check which pods have matching labels:
```bash
# Look for pods with matching labels
$ kubectl get pod -n ui -l app.kubernetes.io/component=service -o jsonpath='{.items[0].metadata.labels}{"\n"}' | jq 
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui",
  "pod-template-hash": "5989474687"
}
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
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.83.84    <none>        80/TCP    15m
```

View service endpoints (the actual pod IPs):
```bash
$ kubectl get endpoints -n ui ui
NAME   ENDPOINTS           AGE
ui     10.42.1.15:8080     15m
```
> This shows which pods receive traffic

Get detailed service information:
```bash
$ kubectl describe service -n ui ui
Name:                     ui
Namespace:                ui
Labels:                   app.kubernetes.io/component=service
                          app.kubernetes.io/created-by=eks-workshop
                          app.kubernetes.io/instance=ui
                          app.kubernetes.io/name=ui
Annotations:              <none>
Selector:                 app.kubernetes.io/component=service,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.16.88.252
IPs:                      172.16.88.252
Port:                     http  80/TCP
TargetPort:               http/TCP
Endpoints:                10.42.129.33:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
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

Let's test service discovery and communication by creating a test pod:

```bash
# Create a test pod for network testing
$ kubectl run test-pod --image=curlimages/curl --restart=Never -- sleep 3600
$ kubectl wait --for=condition=ready pod/test-pod --timeout=60s
```

```bash
# Test DNS resolution from within the cluster
$ kubectl exec test-pod -- nslookup ui.ui.svc.cluster.local
Server:         172.16.0.10
Address:        172.16.0.10:53


Name:   ui.ui.svc.cluster.local
Address: 172.16.88.252
```

```bash
# Test HTTP communication (shows the web page)
$ kubectl exec test-pod -- curl -s http://ui.ui.svc.cluster.local/actuator/info | jq
{
  "pod": {
    "name": "ui-6db5f6bd84-cx4mg"
  }
}
```

### Load Balancing

Services automatically distribute traffic across all healthy pods that match their selector:

**Scale the UI deployment to see load balancing:**
```bash hook=replicas
$ kubectl scale deployment -n ui ui --replicas=3
```

**Watch how the service endpoints update:**
```bash
$ kubectl get endpoints -n ui ui
NAME   ENDPOINTS                                               AGE
ui     10.42.117.212:8080,10.42.129.33:8080,10.42.174.4:8080   11m
```

You'll now see multiple pod IPs listed as endpoints - the service automatically discovered the new pods because they have matching labels.

**Test load balancing:**
```bash
# Make multiple requests to see load balancing in action (single line)
$ for i in $(seq 1 5); do printf "Request %d:" "$i"; kubectl exec test-pod -- curl -s http://ui.ui.svc.cluster.local/actuator/info; echo; sleep 1; done
Request 1:{"pod":{"name":"ui-6db5f6bd84-xgpf4"}}
Request 2:{"pod":{"name":"ui-6db5f6bd84-cx4mg"}}
Request 3:{"pod":{"name":"ui-6db5f6bd84-7bq8w"}}
Request 4:{"pod":{"name":"ui-6db5f6bd84-7bq8w"}}
Request 5:{"pod":{"name":"ui-6db5f6bd84-cx4mg"}}
```

You'll see requests distributed across different pod hostnames, demonstrating how the service load balances across all matching pods.

```bash
# Clean up the test pod
$ kubectl delete pod test-pod
```

## Key Points to Remember

* Services provide stable network endpoints for ephemeral pods
* ClusterIP services enable internal cluster communication
* Services use label selectors to find target pods
* DNS names follow the pattern: service.namespace.svc.cluster.local
* Services automatically load balance traffic across healthy pods
* Use port forwarding to test services locally