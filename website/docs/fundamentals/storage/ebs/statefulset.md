---
title: StatefulSets
sidebar_position: 10
---

Kubernetes  [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) are like a Deployment, a StatefulSet manages Pods that are based on an identical container spec. Unlike a Deployment, a StatefulSet maintains a sticky identity for each of their Pods. These pods are created from the same spec, but are not interchangeable: each has a persistent identifier that it maintains across any rescheduling.

If you want to use storage volumes to provide persistence for your workload, you can use a StatefulSet as part of the solution. Although individual Pods in a StatefulSet are susceptible to failure, the persistent Pod identifiers make it easier to match existing volumes to the new Pods that replace any that have failed.

StatefulSets are valuable for applications that require one or more of the following.

* Stable, unique network identifiers.
* Stable, persistent storage.
* Ordered, graceful deployment and scaling.
* Ordered, automated rolling updates.


On our ecommerce application, we have a StatefulSet already deployed part of our Catalog microservice. The Catalog microservice utilizes a MySQL database running on EKS. Databases are a great example for the use of StatefulSet because they require **persistent storage**. We can analyze our MySQL DB on the catalog service, by running the following command:

```bash
$ kubectl describe statefulsets -n catalog
```

Unfortunately, our MySQL StatefulSet is not utilizing a persistent EBS volume for persistent storage. It's currently just utilizing a [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Run the following command to confirm and check under the "name: data" volume:

```bash
$ kubectl get statefulsets -n catalog -o json | jq '.items[].spec.template.spec.volumes'
[
  {
    "emptyDir": {},
    "name": "conf"
  },
  {
    "emptyDir": {},
    "name": "data"
  }
]
```

An emptyDir volume is first created when a Pod is assigned to a node, and exists as long as that Pod is running on that node. As the name says, the emptyDir volume is initially empty. All containers in the Pod can read and write the same files in the emptyDir volume, though that volume can be mounted at the same or different paths in each container. **When a Pod is removed from a node for any reason, the data in the emptyDir is deleted permanently.** Therefore EmptyDir is not a good fit for our MySQL Database. 

On the next page, we will on understanding the main concepts of Storage on Kubernetes and its integration with the AWS cloud ecosystem. 