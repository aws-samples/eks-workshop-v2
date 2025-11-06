---
title: Other components
sidebar_position: 50
---

In this lab exercise, we'll deploy the rest of the sample application efficiently using the power of Kustomize. The following kustomization file shows how you can reference other kustomizations and deploy multiple components together:

```file
manifests/base-application/kustomization.yaml
```

:::tip
Notice that the catalog API is in this kustomization, didn't we already deploy it?

Because Kubernetes uses a declarative mechanism we can apply the manifests for the catalog API again and expect that because all of the resources are already created Kubernetes will take no action.
:::

Apply this kustomization to our cluster to deploy the rest of the components:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

:::info
As you deploy additional workloads, EKS Auto Mode will automatically provision additional compute instances as needed to accommodate the new Pods.
:::

Watch as EKS Auto Mode provisions a node for your workload. You'll see EKS Auto Mode provision a second node in the general-purpose node pool for our applications. It will also consolidate the system node as there is capacity to move the pods around.

```bash timeout=180
$ kubectl get nodes --watch
...
NAME                  STATUS     ROLES    AGE   VERSION
i-082b0e8be0994671a   NotReady   <none>   1s    v1.33.4-eks-e386d34
...
i-082b0e8be0994671a   Ready      <none>   2s    v1.33.4-eks-e386d34
```

Press `Ctrl+C` to stop watching once you see the node appear. The Pods will now be running:

Kubernetes uses labels for many purposes, for example the nodes have a label that indicates their nodepool, you can inspect them via this command:
```bash
$ kubectl get nodes -o json | jq -c '.items[] | {name: .metadata.name, nodepool: .metadata.labels."karpenter.sh/nodepool"}'
{"name":"i-082b0e8be0994671a","nodepool":"general-purpose"}
{"name":"i-0af75b7f0f828f36c","nodepool":"general-purpose"}
```


After this is complete we can use `kubectl wait` to make sure all the components have started before we proceed:

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

We'll now have a Namespace for each of our application components:

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

We can also see all of resources created for the components:

```bash
$ kubectl get all -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                                  READY   STATUS    RESTARTS      AGE
carts       pod/carts-68d496fff8-h2w84            1/1     Running   1 (75s ago)   89s
carts       pod/carts-dynamodb-995f7768c-s6wv2    1/1     Running   0             89s
catalog     pod/catalog-5fdcc8c65-rrcbh           1/1     Running   3 (68s ago)   89s
catalog     pod/catalog-mysql-0                   1/1     Running   0             88s
checkout    pod/checkout-5b885fb57c-8bkf2         1/1     Running   0             89s
checkout    pod/checkout-redis-69cb79ff4d-vxjlh   1/1     Running   0             89s
orders      pod/orders-74f89d6dbd-pw58j           1/1     Running   0             88s
orders      pod/orders-postgresql-0               1/1     Running   0             88s
ui          pod/ui-5989474687-tqps9               1/1     Running   0             88s

NAMESPACE   NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
carts       service/carts               ClusterIP   172.20.64.186    <none>        80/TCP     89s
carts       service/carts-dynamodb      ClusterIP   172.20.187.59    <none>        8000/TCP   89s
catalog     service/catalog             ClusterIP   172.20.242.75    <none>        80/TCP     89s
catalog     service/catalog-mysql       ClusterIP   172.20.4.209     <none>        3306/TCP   89s
...
```

The sample application is now deployed and ready to provide a foundation for us to use in the rest of the labs in this workshop!

## Next Steps

Now that we have deployed our sample application, pick one of the two options to define your learning journey.

<div style={{display: 'flex', gap: '2rem', marginTop: '2rem', flexWrap: 'wrap'}}>
  <a href="../developer" style={{textDecoration: 'none', color: 'inherit', flex: '1', minWidth: '280px', maxWidth: '400px'}}>
    <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', height: '100%', cursor: 'pointer'}}>
      <h3 style={{marginTop: 0}}>Developer Essentials</h3>
      <p>Learn essential EKS features for deploying and managing containerized applications.</p>
    </div>
  </a>
    <a href="../operator" style={{textDecoration: 'none', color: 'inherit', flex: '1', minWidth: '280px', maxWidth: '400px'}}>
    <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', height: '100%', cursor: 'pointer'}}>
      <h3 style={{marginTop: 0}}>Operator Essentials</h3>
      <p>Learn essential EKS features for managing a container platform.</p>
    </div>
  </a>
</div>
