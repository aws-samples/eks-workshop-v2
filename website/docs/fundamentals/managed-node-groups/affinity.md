---
title: Pod Affinity and Anti-Affinity
sidebar_position: 30
---
Pods can be constrained to run on specific nodes or under specific circumstances. This can include cases where you want only one pod running per node or want pods to be paired together on a node. Additionally, when using node affinity, pods can preferred or mandatory restrictions.

For this lesson, we will focus on inter-pod affinity and anti-affinity by scheduling the `catalog` pods to run only one instance per node and by scheduling the `catalog-redis` pods to only run on nodes where a `catalog` pod exists. This will ensure that our caching pods (`catalog-redis`) run locally with a `catalog` pod instance for best performance. 

The first thing we want to do is see that the `checkout` and `checkout-redis` pods are running
```bash
$ kubectl get pods -n checkout
```
```
NAME                              READY   STATUS    RESTARTS   AGE
checkout-66b6dcbc45-cgrqn         1/1     Running   0          52s
checkout-redis-6656dd7c55-4xrzg   1/1     Running   0          51s
```

We can see both applications have one pod running in the cluster. Now let's find out where they are running.
```bash
$ for i in `kubectl get pods --selector=app.kubernetes.io/name=checkout -A | grep checkout | awk '{print $2}'`; do echo "$i";kubectl describe pod $i -n checkout | grep Node: | awk '{print $2}'; done
```
```
checkout-58f865f584-rn2pb
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
checkout-redis-7f66c6c587-d7g7c
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
```
Based on the results above, the `checkout-58f865f584-rn2pb` pod is running on the `ip-10-42-10-177.us-east-2.compute` node while the `checkout-redis-7f66c6c587-d7g7c` pod is running on the `ip-10-42-10-177.us-east-2.compute.internal` node.

> **Note**: in your environment the pods may be running on the same node initially

Let's set up a `podAntiAffinity` policy in the **checkout** deployment specifying that any pods matching `app.kubernetes.io/component=service` can not be scheduled on the same node. We will use the `requiredDuringSchedulingIgnoredDuringExecution` to make this a requirement.

To make the change, run the following command to modify the **checkout** deployment in your cluster
```bash
$ kubectl apply -k /workspace/modules/fundamentals/affinity/checkout/
```
The command adds an `affinity` section to the **checkout** deployment specifying a **podAntiAffinity** policy.
```kustomization
fundamentals/affinity/checkout-redis/checkout.yaml
Deployment/checkout
```
The **podAntiAffinity** section requires that no `checkout` pods are already running on the node and is accomplished by matching the **`app.kubernetes.io/component=service`** label

With the `checkout` deployment updated to require that only one pod can run per node, let's scale the deployment to ensure it deploys to the second node

```bash
$ kubectl scale --replicas=2 deployment/checkout --namespace checkout
```
Ensure that both pods are up and running
```bash
$ kubectl get pods -n checkout
```
```
NAME                              READY   STATUS    RESTARTS   AGE
checkout-58f865f584-hbql9         1/1     Running   0          7s
checkout-58f865f584-rn2pb         1/1     Running   0          2m13s
checkout-redis-6656dd7c55-4xrzg   1/1     Running   0          11m
```

Now validate where each pod is running
```bash
$ for i in `kubectl get pods --selector=app.kubernetes.io/name=checkout -A | grep checkout | awk '{print $2}'`; do echo "$i";kubectl describe pod $i -n checkout | grep Node: | awk '{print $2}'; done
```
```
checkout-58f865f584-hbql9
ip-10-42-12-141.us-east-2.compute.internal/10.42.12.141
checkout-58f865f584-rn2pb
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
checkout-redis-6656dd7c55-4xrzg
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
```
In this example, the two `checkout` pods are running on `ip-10-42-12-141.us-east-2.compute.internal` and `ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177`, as required by the **podAntiAffinity** policy we defined in the deployment

Next, let's modify the `checkout-redis` deployment policies to require that future pods both run individually per node and only run on nodes where a `checkout` pod exists. To do this we will need to update the `checkout-redis` deployment
```bash
$ kubectl apply -k /workspace/modules/fundamentals/affinity/checkout-redis/
```

The command adds an `affinity` section to the **checkout-redis** deployment specifying both a **podAffinity** and **podAntiAffinity** policy
```kustomization
fundamentals/affinity/checkout-redis/checkout-redis.yaml
Deployment/checkout-redis
```

As you can see, for the `checkout-redis` deployment we are adding **podAffinity** and **podAntiAffinity** statements. The **podAffinity** section requires that a `checkout` pod exist on the node before deploying. This is accomplished by matching the **`app.kubernetes.io/component=service`** label. The **podAntiAffinity** section requires that no `checkout-redis` pods are already running on the node and is accomplished by matching the **`app.kubernetes.io/component=redis`** label.

Now, let's scale the `checkout-redis` deployment
```bash
$ kubectl scale --replicas=2 deployment/checkout-redis --namespace checkout
```
Check the running pods to verify that there are now four (4) running
```bash
$ kubectl get pods -n checkout
```
```                                             
NAME                              READY   STATUS    RESTARTS   AGE
checkout-58f865f584-hbql9         1/1     Running   0          7m16s
checkout-58f865f584-rn2pb         1/1     Running   0          9m22s
checkout-redis-7f66c6c587-b6tg6   1/1     Running   0          88s
checkout-redis-7f66c6c587-v4czw   1/1     Running   0          20s
```

We can also verify where the pods are running to ensure the **podAffinity** and **podAntiAffinity** policies are being followed

```bash
$ for i in `kubectl get pods --selector=app.kubernetes.io/name=checkout -A | grep checkout | awk '{print $2}'`; do echo "$i";kubectl describe pod $i -n checkout | grep Node: | awk '{print $2}'; done
```
```
checkout-58f865f584-hbql9
ip-10-42-12-141.us-east-2.compute.internal/10.42.12.141
checkout-58f865f584-rn2pb
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
checkout-redis-7f66c6c587-b6tg6
ip-10-42-12-141.us-east-2.compute.internal/10.42.12.141
checkout-redis-7f66c6c587-v4czw
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
```

All looks good on the pod scheduling, but we can further verify by scaling the `checkout-redis` pod again to see where a third pod will deploy
```bash
$ kubectl scale --replicas=3 deployment/checkout --namespace checkout
```
If we check the running pods we can see that the third `checkout-redis` pod has been placed in a **Pending** state since there are only two (2) nodes and both already have a pod deployed
```bash
$ kubectl get pods -n checkout
```
```
NAME                              READY   STATUS    RESTARTS   AGE
checkout-58f865f584-hbql9         1/1     Running   0          8m48s
checkout-58f865f584-rn2pb         1/1     Running   0          10m
checkout-redis-7f66c6c587-b6tg6   1/1     Running   0          3m
checkout-redis-7f66c6c587-cf268   0/1     Pending   0          18s
checkout-redis-7f66c6c587-v4czw   1/1     Running   0          112s
```
To clean up the environment, scale both deployments back down to one (1)
```bash
$ kubectl scale --replicas=1 deployment/checkout-redis --namespace checkout; kubectl scale --replicas=1 deployment/checkout --namespace checkout
```

Verify that only two (2) pods are running in the `checkout` namespace
```bash
$ kubectl get pods -n checkout 
```
```
NAME                              READY   STATUS    RESTARTS   AGE
checkout-58f865f584-rn2pb         1/1     Running   0          13m
checkout-redis-7f66c6c587-b6tg6   1/1     Running   0          5m38s
```

Check where the two remaining pods are located on the cluster
```bash
$ for i in `kubectl get pods --selector=app.kubernetes.io/name=checkout -A | grep checkout | awk '{print $2}'`; do echo "$i";kubectl describe pod $i -n checkout | grep Node: | awk '{print $2}'; done
```
```
checkout-58f865f584-rn2pb
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
checkout-redis-7f66c6c587-b6tg6
ip-10-42-12-141.us-east-2.compute.internal/10.42.12.141
```
In our cluster the `checkout` and `checkout-redis` pods are running on different nodes
> **Note**: In your cluster they may be co-located on the same node

If the pods are **NOT** co-located, delete the `checkout-redis` pod and let the scheduler start a new one. 
```bash
$ kubectl delete pod `kubectl get pods -n checkout | grep redis | awk '{print $1}'` -n checkout
```
```
pod "checkout-redis" deleted
```

Verify that the new pod is still following the affinity rules and is deployed to the same node as the `checkout` pod
```bash
$ for i in `kubectl get pods --selector=app.kubernetes.io/name=checkout -A | grep checkout | awk '{print $2}'`; do echo "$i";kubectl describe pod $i -n checkout | grep Node: | awk '{print $2}';done
```
```
checkout-58f865f584-rn2pb
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
checkout-redis-7f66c6c587-d7g7c
ip-10-42-10-177.us-east-2.compute.internal/10.42.10.177
```
