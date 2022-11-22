---
title: Pod Affinity and Anti-Affinity
sidebar_position: 30
---
Pods can be constrained to run on specific nodes or under specific circumstances. This can include cases where you want only one Pod running per node or want Pods to be paired together on a node. Additionally, when using node affinity Pods can have preferred or mandatory restrictions.

For this lesson, we will focus on inter-Pod affinity and anti-affinity by scheduling the `checkout` Pods to run only one instance per node and by scheduling the `checkout-redis` Pods to only run on nodes where a `checkout` Pod exists. This will ensure that our caching Pods (`checkout-redis`) run locally with a `checkout` Pod instance for best performance. 

The first thing we want to do is see that the `checkout` and `checkout-redis` Pods are running:

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-vzkzw         1/1     Running   0          125m
checkout-redis-6cfd7d8787-kxs8r   1/1     Running   0          127m
```

We can see both applications have one Pod running in the cluster. Now let's find out where they are running:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-698856df4d-vzkzw       ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

Based on the results above, the `checkout-698856df4d-vzkzw` Pod is running on the `ip-10-42-11-142.us-west-2.compute.internal` node while the `checkout-redis-6cfd7d8787-kxs8r` Pod is running on the `ip-10-42-10-225.us-west-2.compute.internal` node.

:::note
In your environment the Pods may be running on the same node initially
:::

Let's set up a `podAntiAffinity` policy in the **checkout** deployment specifying that any Pods matching `app.kubernetes.io/component=service` can not be scheduled on the same node. We will use the `requiredDuringSchedulingIgnoredDuringExecution` to make this a requirement, rather than a preferred behavior.

The following kustomization adds an `affinity` section to the **checkout** deployment specifying a **podAntiAffinity** policy:

```kustomization
fundamentals/affinity/checkout-redis/checkout.yaml
Deployment/checkout
```

To make the change, run the following command to modify the **checkout** deployment in your cluster:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/affinity/checkout/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
$ kubectl rollout status deployment/checkout \
  -n checkout --timeout 180s
```

The **podAntiAffinity** section requires that no `checkout` Pods are already running on the node by matching the **`app.kubernetes.io/component=service`** label. Now lets scale up the Deployment to check the configuration is working:

```bash
$ kubectl scale -n checkout deployment/checkout --replicas 2
```

Now validate where each Pod is running:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

In this example the `checkout` Pods are running on separate nodes `ip-10-42-12-31.us-west-2.compute.internal` and `ip-10-42-11-142.us-west-2.compute.internal`, as required by the **podAntiAffinity** policy we defined in the deployment.

Next, let's modify the `checkout-redis` deployment policies to require that future Pods both run individually per node and only run on nodes where a `checkout` Pod exists. To do this we will need to update the `checkout-redis` deployment specifying both a **podAffinity** and **podAntiAffinity** policy.:

```kustomization
fundamentals/affinity/checkout-redis/checkout-redis.yaml
Deployment/checkout-redis
```

Apply it with the following command:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/affinity/checkout-redis/
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout unchanged
deployment.apps/checkout-redis configured
$ kubectl rollout status deployment/checkout-redis \
  -n checkout --timeout 180s
```

For the `checkout-redis` deployment we are adding **podAffinity** and **podAntiAffinity** fields. The **podAffinity** section requires that a `checkout` Pod exist on the node before deploying by matching the **`app.kubernetes.io/component=service`** label. The **podAntiAffinity** section requires that no `checkout-redis` Pods are already running on the node by matching the **`app.kubernetes.io/component=redis`** label.

```bash
$ kubectl scale -n checkout deployment/checkout-redis --replicas 2
```

Check the running Pods to verify that there are now two of each running:

```bash
$ kubectl get pods -n checkout                                       
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-6ddwn        1/1     Running   0          4m14s
checkout-5b68c8cddf-rd7xf        1/1     Running   0          4m12s
checkout-redis-7979df659-cjfbf   1/1     Running   0          19s
checkout-redis-7979df659-pc6m9   1/1     Running   0          22s
```

We can also verify where the Pods are running to ensure the **podAffinity** and **podAntiAffinity** policies are being followed:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-7979df659-57xcb  ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-7979df659-r7kkm  ip-10-42-12-31.us-west-2.compute.internal
```

All looks good on the Pod scheduling, but we can further verify by scaling the `checkout-redis` Pod again to see where a third Pod will deploy:

```bash
$ kubectl scale --replicas=3 deployment/checkout-redis --namespace checkout
```

If we check the running Pods we can see that the third `checkout-redis` Pod has been placed in a **Pending** state since there are only two nodes and both already have a Pod deployed:

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-bn8bp        1/1     Running   0          4m59s
checkout-5b68c8cddf-clnps        1/1     Running   0          6m9s
checkout-redis-7979df659-57xcb   1/1     Running   0          35s
checkout-redis-7979df659-lb69n   0/1     Pending   0          6s
checkout-redis-7979df659-r7kkm   1/1     Running   0          2m10s
```

Lets finish this section by removing the Pending Pod:

```bash
$ kubectl scale --replicas=2 deployment/checkout-redis --namespace checkout
```