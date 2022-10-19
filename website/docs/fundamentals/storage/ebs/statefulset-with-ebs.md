---
title: StatefulSet with EBS Volume
sidebar_position: 30
---

Now that we understand [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) and [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/), let's change our MySQL DB on the Catalog microservice to provision a new EBS volume to store database files persistent. 

Utilizing Kustomize, we'll do two things on our `catalog-mysql` StatefulSet:
* Remove the EmptyDir volume with `data` named
* Add the `VolumeClaimTemplates` section, so Kubernetes will utilize the Dynamic Volume Provisioning to create a new EBS Volume, a [PersistentVolume (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and a [PersistentVolumeClaim (PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) all automatically. 

```kustomization
fundamentals/storage/ebs/statefulset-mysql.yaml
StatefulSet/catalog-mysql
```

To apply, the changes. We first need to delete the current `catalog-mysql` StatefulSet because StatefulSets [do not allow the update of underline persistent storage](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#limitations). It requires to re-create the StatefulSet object from scratch. First let's delete it: 

```bash
$ kubectl delete statefulset catalog-mysql -n catalog
pod "catalog-mysql-0" deleted
$ kubectl wait --for=delete pod catalog-mysql-0 -n catalog --timeout=120s
```

Finally, we can apply the Kustomize changes to a new `StatefulSet` deployment. Run the following commands:

```bash hook=check-pvc
$ kubectl apply -k /workspace/modules/fundamentals/storage/ebs/
namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog configured
secret/catalog-reader-db unchanged
secret/catalog-writer-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
deployment.apps/catalog unchanged
statefulset.apps/catalog-mysql created
$ kubectl rollout status --timeout=60s statefulset/catalog-mysql -n catalog
```

It takes a couple of seconds for our newly deployed `StatefulSet` to be deployed and have a `PV` EBS volume attached to it. Run the command to wait for the proper status to be Ready:

```bash
$ kubectl wait --for=condition=ready pod catalog-mysql-0 -n catalog --timeout=60s
pod/catalog-mysql-0 condition met
```

Let's now confirm that our newly deployed `StatefulSet` is running:

```bash
$ kubectl get statefulset -n catalog
NAME            READY   AGE
catalog-mysql   1/1     79s
```

Inspecting our `catalog-mysql StatefulSet`, we can see that now we have a `PersistentVolumeClaim` attached to it with 30GiB and with storageClassName of gp2. 

```bash
$ kubectl get statefulsets -n catalog -o json | jq '.items[].spec.volumeClaimTemplates'
```

We can analyze how the Dynamic Volume Provisioning created a PersistentVolume (PV) automatically for us:

```bash
$ kubectl get pv | grep -i catalog
pvc-1df77afa-10c8-4296-aa3e-cf2aabd93365   30Gi       RWO            Delete           Bound         catalog/data-catalog-mysql-0          gp2                            10m
```

Utilizing the [AWS CLI](https://aws.amazon.com/cli/), we can check the Amazon EBS volume that got created automatically for us:
```bash
$ aws ec2 describe-volumes \
    --filters Name=tag:kubernetes.io/created-for/pv/name,Values=`kubectl get pvc -n catalog -o jsonpath='{.items[].spec.volumeName}'` \
    --query "Volumes[*].{ID:VolumeId,Tag:Tags}" \
    --no-cli-pager
```

If you prefer you can also check it via the AWS console, just look for the EBS volumes with the tag of key  `kubernetes.io/created-for/pvc/name` and value of `data-catalog-mysql-0`:

![EBS Volume AWS Console Screenshot](./assets/ebsVolumeScrenshot.png)


If you'd like to inspect the container shell and check out the newly EBS volume attached to the Linux OS, run this instructions to runa shell command into the `mysql-catalog` container. It'll inspect the filesystems that you have mounted:

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c "df -h"
Filesystem      Size  Used Avail Use% Mounted on
overlay         100G  7.6G   93G   8% /
tmpfs            64M     0   64M   0% /dev
tmpfs           3.8G     0  3.8G   0% /sys/fs/cgroup
/dev/nvme0n1p1  100G  7.6G   93G   8% /etc/hosts
shm              64M     0   64M   0% /dev/shm
/dev/nvme1n1     30G  211M   30G   1% /var/lib/mysql
tmpfs           7.0G   12K  7.0G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs           3.8G     0  3.8G   0% /proc/acpi
tmpfs           3.8G     0  3.8G   0% /sys/firmware
```

Check the `/dev/nvme2n1` disk that is currently being mounted on the `/var/lib/mysql`. This is the EBS Volume for the stateful MySQL database files that being stored in a persistent way. 

Let's now test if our data is in fact persistent. We'll create the same `test.txt` file exactly the same way as we did on the first section of this module:

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "echo 123 > /var/lib/mysql/test.txt"
```

Now let's verify that our `test.txt` file got created on the `/var/lib/mysql` directory:

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "ls -larth /var/lib/mysql/ | grep -i test"
-rw-r--r-- 1 root  root     4 Oct 18 13:57 test.txt
```

Now let's remove the current `catalog-mysql` pod. This will force the StatefulSet controller to automatically re-create a new catalog-mysql pod:

```bash hook=pod-delete
$ kubectl delete pods -n catalog catalog-mysql-0
pod "catalog-mysql-0" deleted
$ kubectl wait --for=delete pod catalog-mysql-0 -n catalog --timeout=120s
```

Wait for a few seconds, and run the command below to check if the `catalog-mysql` pod has been re-created:

```bash
$ kubectl wait --for=condition=Ready pod -n catalog -l app.kubernetes.io/team=database --timeout=60s
pod/catalog-mysql-0 condition met
$ kubectl get pods -n catalog -l app.kubernetes.io/team=database
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          29s
```

Finally, let's exec back into the MySQL container shell and run a `ls` command on the `/var/lib/mysql` path trying to look for the `test.txt` file that we created, and see if the file has now persisted:

```bash
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "ls -larth /var/lib/mysql/ | grep -i test"
-rw-r--r-- 1 mysql root     4 Oct 18 13:57 test.txt
$ kubectl exec --stdin catalog-mysql-0  -n catalog -- bash -c  "cat /var/lib/mysql/test.txt"
123
```

As you can see the `test.txt` file is still available after a pod delete and restart and with the right text on it `123`. This is the main functionality of Persistent Volumes (PVs). Amazon EBS is storing the data and keeping our data safe and available across an AWS Availability Zone (AZ).

