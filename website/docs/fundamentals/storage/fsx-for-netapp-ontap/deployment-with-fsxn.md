---
title: Dynamic provisioning using FSx for NetApp ONTAP
sidebar_position: 30
---

Now that we understand the FSxN storage class for Kubernetes let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the `assets` container on the assets deployment to mount the Volume created.

First inspect the `fsxnpvclaim.yaml` file to see the parameters in the file and the claim of the specific storage size of 5GB from the Storage class `fsxn-sc-nfs` we created in the earlier step:

```file
fundamentals/storage/fsxn/deployment/fsxnpvclaim.yaml
```

We'll also modify the assets service is two ways:

* Mount the PVC to the location where the assets images are stored
* Add an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to copy the initial images to the FSxN volume

```kustomization
fundamentals/storage/fsxn/deployment/deployment.yaml
Deployment/assets
```

We can apply the changes by running the following command:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/storage/fsxn/deployment
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolumeclaim/fsxn-nfs-claim created
deployment.apps/assets configured
$ kubectl rollout status --timeout=130s deployment/assets -n assets
```

Now look at the `volumeMounts` in the deployment, notice that we have our new `Volume` named `efsvolume` mounted on`volumeMounts` named `/usr/share/nginx/html/assets`:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts' 
- mountPath: /usr/share/nginx/html/assets
  name: fsxnvolume
- mountPath: /tmp
  name: tmp-volume
```

A PersistentVolume (PV) has been created automatically for the PersistentVolumeClaim (PVC) we had created in the previous step:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-ceec6f39-8034-4b33-a4bc-c1b1370befd1   5Gi        RWX            Delete           Bound    assets/fsxn-nfs-claim                 fsxn-sc-nfs             173m
```

Also describe the PersistentVolumeClaim (PVC) created:

```bash
$ kubectl describe pvc -n assets
Name:          fsxn-nfs-claim
Namespace:     assets
StorageClass:  fsxn-sc-nfs
Status:        Bound
Volume:        pvc-ceec6f39-8034-4b33-a4bc-c1b1370befd1
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: csi.trident.netapp.io
               volume.kubernetes.io/storage-provisioner: csi.trident.netapp.io
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       assets-555dc4c9c9-g8hfs
               assets-555dc4c9c9-m6r2l
Events:        <none>
```

Now create a new file `newproduct.png` under the assets directory in the first Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -- bash -c 'touch /usr/share/nginx/html/assets/newproduct.png'
```

And verify that the file now also exists in the second Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
newproduct.png <-----------
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
test.txt
wood_watch.jpg
```

Now as you can see even though we created a file through the first Pod the second Pod also has access to this file because of the shared FSxN file system.
