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

As you can see the [`volumeMounts`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) section of our `StatefulSet` defines what is the `monuntPath` that will be mounted into a specific volume:

```blank title="manifests/catalog/statefulset-mysql.yaml" 
          volumeMounts:
            - name: data
              mountPath: /var/lib/mysql
      volumes:
        - name: data
          emptyDir: {}
```

In our case the `volumeMounts` called `data` has a `mountPath` of `/var/lib/mysql` directory, Kubernetes will map to a `volume` with the same name, which is the `emptyDir` with name of `data` that you see on the last two lines of the snippet above. 

Unfortunately, our MySQL StatefulSet is not utilizing a persistent EBS volume for persistent storage. It's currently just utilizing a [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Run the following command to confirm and check under the `name: data` volume:

```bash
$ kubectl get statefulsets -n catalog -o json | jq '.items[].spec.template.spec.volumes'
[
  {
    "emptyDir": {},
    "name": "data"
  }
]
```

An emptyDir volume is first created when a Pod is assigned to a node, and exists as long as that Pod is running on that node. As the name says, the emptyDir volume is initially empty. All containers in the Pod can read and write the same files in the emptyDir volume, though that volume can be mounted at the same or different paths in each container. **When a Pod is removed from a node for any reason, the data in the emptyDir is deleted permanently.** Therefore EmptyDir is not a good fit for our MySQL Database. 

We can test by creating a shell inside the container that is running MySQL and creating a test file. Then after that, we'll delete the pod that is running our StatefulSet. Because that pod is not using a Persistent Volume (PV), it's using a EmptyDir, the file will not survive a pod restart. First let's run a command inside our MySQL container to create a file on the emptyDir `var/lib/mysql` path (where MySQL saves database files): 

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "echo 123 > /var/lib/mysql/test.txt"
```

Now let's verify that our `test.txt` file got created on the `/var/lib/mysql` directory:

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "ls -larth /var/lib/mysql/ | grep -i test"
-rw-r--r-- 1 root  root     4 Oct 18 13:38 test.txt
```

Now let's remove the current `catalog-mysql` pod. This will force the StatefulSet controller to automatically re-create a new catalog-mysql pod:

```bash
$ kubectl delete pods -n catalog -l app.kubernetes.io/team=database
pod "catalog-mysql-0" deleted
```

Wait for a few seconds, and run the command below to check if the `catalog-mysql` pod has been re-created:

```bash
$ kubectl wait --for=condition=Ready pod -n catalog -l app.kubernetes.io/team=database --timeout=30s
pod/catalog-mysql-0 condition met
$ kubectl get pods -n catalog -l app.kubernetes.io/team=database
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          29s
```

Finally, let's exec back into the MySQL container shell and run a `ls` command on the `/var/lib/mysql` path trying to look for the `test.txt` file that we created:

```bash expectError=true
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "ls -larth /var/lib/mysql/ | grep -i test"
command terminated with exit code 1
```

```bash expectError=true
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "cat /var/lib/mysql/test.txt"
cat: /var/lib/mysql/test.txt: No such file or directory
command terminated with exit code 1
```

As you can see the `test.txt` file is no longer there, because emptyDir volumes are ephemeral. On future sections, we'll run the same experiment and demostrate how Persistent Volumes (PVs) will keep the `test.txt` file and survive pod restarts and/or failures. 

On the next page, we will on understanding the main concepts of Storage on Kubernetes and its integration with the AWS cloud ecosystem. 