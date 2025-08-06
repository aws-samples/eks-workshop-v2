---
title: Services
sidebar_position: 40
---

# Services

Services provide stable network endpoints for accessing your applications. While Pods come and go, Services provide a consistent way to reach them.

## Why Do We Need Services?

Pods are ephemeral - they get created, destroyed, and recreated with different IP addresses. Services solve this by:

- **Stable endpoint** - Consistent IP and DNS name
- **Load balancing** - Distributes traffic across multiple Pods
- **Service discovery** - Other applications can find your service
- **Abstraction** - Decouples consumers from Pod details

## Service Types

### ClusterIP (Default)
- Internal to the cluster only
- Other Pods can access it
- Most common type for internal communication

### NodePort
- Exposes service on each node's IP at a static port
- Accessible from outside the cluster
- Port range: 30000-32767

### LoadBalancer
- Creates an external load balancer (cloud provider specific)
- Automatically creates NodePort and ClusterIP
- Best for production external access

## Creating Your First Service

Let's start with a Deployment and then expose it with a Service:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
EOF
```

Now create a ClusterIP Service:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

## Understanding Service Configuration

Let's examine the Service:

```bash
$ kubectl get service web-app-service
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-app-service   ClusterIP   10.100.200.10   <none>        80/TCP    1m
```

Key components:
- **selector** - Matches Pods with `app: web-app` label
- **port** - Port the Service listens on
- **targetPort** - Port on the Pod containers
- **type** - Service type (ClusterIP, NodePort, LoadBalancer)

## Service Discovery

Services get DNS names automatically:

```bash
# From within the cluster, you can access:
# web-app-service (same namespace)
# web-app-service.default.svc.cluster.local (full DNS name)
```

Test service discovery:

```bash
$ kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh
# Inside the pod:
/ # nslookup web-app-service
/ # wget -qO- web-app-service
```

## Load Balancing

Services automatically load balance across all matching Pods:

```bash
$ kubectl get endpoints web-app-service
NAME              ENDPOINTS                                      AGE
web-app-service   10.244.1.10:80,10.244.1.11:80,10.244.2.12:80   5m
```

The endpoints show all Pod IPs that match the selector.

## NodePort Service

Create a NodePort Service for external access:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
EOF
```

Check the Service:

```bash
$ kubectl get service web-app-nodeport
NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-app-nodeport   NodePort   10.100.200.20   <none>        80:30080/TCP   1m
```

Now you can access the service at `<node-ip>:30080`.

## LoadBalancer Service (EKS)

In EKS, LoadBalancer Services create AWS Application Load Balancers:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-loadbalancer
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
EOF
```

Wait for the external IP:

```bash
$ kubectl get service web-app-loadbalancer -w
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
web-app-loadbalancer   LoadBalancer   10.100.200.30   a1b2c3d4e5f6-123456789.us-west-2.elb.amazonaws.com   80:31234/TCP   2m
```

## Headless Services

Sometimes you don't want load balancing - you want to connect to specific Pods:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-headless
spec:
  clusterIP: None  # This makes it headless
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF
```

Headless Services return Pod IPs directly in DNS queries.

## Service Without Selector

You can create Services that point to external resources:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-service
subsets:
- addresses:
  - ip: 1.2.3.4
  ports:
  - port: 80
EOF
```

## Multi-Port Services

Services can expose multiple ports:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: web-app
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  - name: https
    protocol: TCP
    port: 443
    targetPort: 443
EOF
```

## Session Affinity

By default, Services load balance randomly. You can enable session affinity:

```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

## Troubleshooting Services

### Service not accessible
```bash
$ kubectl get service <service-name>
$ kubectl describe service <service-name>
$ kubectl get endpoints <service-name>
```

### No endpoints
- Check if Pods are running: `kubectl get pods -l <selector>`
- Verify Pod labels match Service selector
- Check if Pods are ready (readiness probes)

### DNS not working
```bash
$ kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>
```

## Service Networking Deep Dive

### How Services Work
1. **kube-proxy** runs on each node
2. Watches for Service and Endpoint changes
3. Updates iptables/IPVS rules
4. Routes traffic to healthy Pods

### Service IP Allocation
- Services get IPs from the cluster's service CIDR
- These IPs only exist in the cluster
- kube-proxy handles the routing magic

## Best Practices

1. **Use meaningful names** - Service names become DNS entries
2. **Label consistently** - Ensure selectors match Pod labels
3. **Configure health checks** - Only ready Pods receive traffic
4. **Use ClusterIP for internal** - Most services should be internal
5. **Use LoadBalancer for external** - Better than NodePort for production
6. **Consider headless** - When you need direct Pod access
7. **Monitor endpoints** - Ensure Services have healthy targets

## Cleanup

Remove all the resources we created:

```bash
$ kubectl delete deployment web-app
$ kubectl delete service web-app-service web-app-nodeport web-app-loadbalancer web-app-headless external-service multi-port-service
```

## What's Next?

Now that you understand how Services enable communication, let's learn about [Configuration](../configuration) - how to manage application settings and sensitive data using ConfigMaps and Secrets.