---
title: Pod Affinity and Anti-Affinity
sidebar_position: 30
---
Pods can be constrained to run on specific nodes or under specific circumstances. This can include cases where you want only one application pod running per node or want pods to be paired together on a node. Additionally, when using node affinity pods can have preferred or mandatory restrictions.

For this lesson, we'll focus on inter-pod affinity and anti-affinity by scheduling the `checkout-redis` pods to run only one instance per node and by scheduling the `checkout` pods to only run one instance of it on nodes where a `checkout-redis` pod exists. This will ensure that our caching pods (`checkout-redis`) run locally with a `checkout` pod instance for best performance. 

The first thing we want to do is see that the `checkout` and `checkout-redis` pods are running:

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-vzkzw         1/1     Running   0          125m
checkout-redis-6cfd7d8787-kxs8r   1/1     Running   0          127m
```

We can see both applications have one pod running in the cluster. Now, let's find out where they are running:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-698856df4d-vzkzw       ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-6cfd7d8787-kxs8r ip-10-42-10-225.us-west-2.compute.internal
```

Based on the results above, the `checkout-698856df4d-vzkzw` pod is running on the `ip-10-42-11-142.us-west-2.compute.internal` node and the `checkout-redis-6cfd7d8787-kxs8r` pod is running on the `ip-10-42-10-225.us-west-2.compute.internal` node.

:::note
In your environment the pods may be running on the same node initially
:::

Let's set up a `podAffinity` and `podAntiAffinity` policy in the **checkout** deployment to ensure that one `checkout` pod runs per node, and that it will only run on nodes where a `checkout-redis` pod is already running. We'll use the `requiredDuringSchedulingIgnoredDuringExecution` to make this a requirement, rather than a preferred behavior.

The following kustomization adds an `affinity` section to the **checkout** deployment specifying both **podAffinity** and **podAntiAffinity** policies:

```kustomization
fundamentals/affinity/checkout/checkout.yaml
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

The **podAffinity** section ensures that a `checkout-redis` pod is already running on the node — this is because we can assume the `checkout` pod requires `checkout-redis` to run correctly. The **podAntiAffinity** section requires that no `checkout` pods are already running on the node by matching the **`app.kubernetes.io/component=service`** label. Now, let's scale up the deployment to check the configuration is working:

```bash
$ kubectl scale -n checkout deployment/checkout --replicas 2
```

Now validate where each pod is running:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-6c7c9cdf4f-p5p6q       ip-10-42-10-120.us-west-2.compute.internal
checkout-6c7c9cdf4f-wwkm4
checkout-redis-6cfd7d8787-gw59j ip-10-42-10-120.us-west-2.compute.internal
```

In this example, the first `checkout` pod runs on the same pod as the existing checkout-redis pod, as it fulfills the **podAffinity** rule we set. The second one is still pending, because the **podAntiAffinity** rule we defined does not allow two checkout pods to get started on the same node. As the second node doesn't have a `checkout-redis` pod running, it will stay pending.

Next, we'll scale the `checkout-redis` to two instances for our two nodes, but first let's modify the `checkout-redis` deployment policy to spread out our `checkout-redis` instances across each node. To do this, we'll simply need to create a **podAntiAffinity** rule.

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

The **podAntiAffinity** section requires that no `checkout-redis` pods are already running on the node by matching the **`app.kubernetes.io/component=redis`** label.

```bash
$ kubectl scale -n checkout deployment/checkout-redis --replicas 2
```

Check the running pods to verify that there are now two of each running:

```bash
$ kubectl get pods -n checkout                                       
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-6ddwn        1/1     Running   0          4m14s
checkout-5b68c8cddf-rd7xf        1/1     Running   0          4m12s
checkout-redis-7979df659-cjfbf   1/1     Running   0          19s
checkout-redis-7979df659-pc6m9   1/1     Running   0          22s
```

We can also verify where the pods are running to ensure the **podAffinity** and **podAntiAffinity** policies are being followed:

```bash
$ kubectl get pods -n checkout \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}'
checkout-5b68c8cddf-bn8bp       ip-10-42-11-142.us-west-2.compute.internal
checkout-5b68c8cddf-clnps       ip-10-42-12-31.us-west-2.compute.internal
checkout-redis-7979df659-57xcb  ip-10-42-11-142.us-west-2.compute.internal
checkout-redis-7979df659-r7kkm  ip-10-42-12-31.us-west-2.compute.internal
```

All looks good on the pod scheduling, but we can further verify by scaling the `checkout` pod again to see where a third pod will deploy:

```bash
$ kubectl scale --replicas=3 deployment/checkout --namespace checkout
```

If we check the running pods we can see that the third `checkout` pod has been placed in a **Pending** state since there are only two nodes and both already have a pod deployed:

```bash
$ kubectl get pods -n checkout
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5b68c8cddf-bn8bp        1/1     Running   0          4m59s
checkout-5b68c8cddf-clnps        1/1     Running   0          6m9s
checkout-5b68c8cddf-lb69n        0/1     Pending   0          6s
checkout-redis-7979df659-57xcb   1/1     Running   0          35s
checkout-redis-7979df659-r7kkm   1/1     Running   0          2m10s
```

Let's finish this section by removing the Pending pod:

```bash
$ kubectl scale --replicas=2 deployment/checkout --namespace checkout
```
