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

We can test by creating a shell inside the container that is running MySQL and creating a test file. Then after that, we'll delete the pod that is running our StatefulSet. Because that pod is not using a Persistent Volume (PV), it's using a EmptyDir, the file will not survive a pod restart. First let's shell inside the MySQL container. 

```bash
$ kubectl exec --stdin --tty catalog-mysql-0  -n catalog -- /bin/bash
```

Now, let's create a file inside the "var/lib/mysql" directory, which is using the EmptyDir

```bash
$ echo test123 > /var/lib/mysql/test.txt
```

```bash
$ ls /var/lib/mysql
auto.cnf    catalog          ib_buffer_pool  ibdata1  mysql.sock          public_key.pem   sys
ca-key.pem  client-cert.pem  ib_logfile0     ibtmp1   performance_schema  server-cert.pem  test.txt
ca.pem      client-key.pem   ib_logfile1     mysql    private_key.pem     server-key.pem
```

**Exit the container shell press Control + D, and you'll return to the Cloud9 shell**

Now let's remove the current catalog-mysql pod. This will force the StatefulSet controller to automatically re-create a new catalog-mysql pod:

```bash
$ kubectl delete pods -n catalog -l app.kubernetes.io/team=database
pod "catalog-mysql-0" deleted
```

```bash
$ kubectl get pods -n catalog -l app.kubernetes.io/team=database
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          29s
```

Finally, let's exec back into the MySQL container shell to see if our file has disappeared:

```bash
$ kubectl exec --stdin --tty catalog-mysql-0  -n catalog -- /bin/bash
```

```bash
$ ls /var/lib/mysql
auto.cnf    catalog          ib_buffer_pool  ibdata1  mysql.sock          public_key.pem   sys
ca-key.pem  client-cert.pem  ib_logfile0     ibtmp1   performance_schema  server-cert.pem
ca.pem      client-key.pem   ib_logfile1     mysql    private_key.pem     server-key.pem
```

```bash
$ cat /var/lib/mysql/test.txt
cat: /var/lib/mysql/test.txt: No such file or directory
```

As you can see the *test.txt* file is no longer there, because emptyDir volumes are ephemeral. On future sections, we'll run the same experiment and demostrate how Persistent Volumes (PVs) will keep the *test.txt* file and survive pod restarts and/or failures. 

**Exit the container shell press Control + D, and you'll return to the Cloud9 shell**


On the next page, we will on understanding the main concepts of Storage on Kubernetes and its integration with the AWS cloud ecosystem. 