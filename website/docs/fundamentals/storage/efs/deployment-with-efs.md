---
title: Dynamic provisioning using EFS
sidebar_position: 30
---

Now that we understand the EFS storage class for Kubernetes let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the `assets` container on the assets deployment to mount the Volume created.

First inspect the `efspvclaim.yaml` file to see the parameters in the file and the claim of the specific storage size of 5GB from the Storage class `efs-sc` we created in the earlier step:

```file
fundamentals/storage/efs/deployment/efspvclaim.yaml
```

We'll also modify the assets service is two ways:

* Mount the PVC to the location where the assets images are stored
* Add an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to copy the initial images to the EFS volume

```kustomization
fundamentals/storage/efs/deployment/deployment.yaml
Deployment/assets
```

We can apply the changes by running the following command:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/storage/efs/deployment
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolumeclaim/efs-claim created
deployment.apps/assets configured
$ kubectl rollout status --timeout=130s deployment/assets -n assets
```

Now look at the `volumeMounts` in the deployment, notice that we have our new `Volume` named `efsvolume` mounted on`volumeMounts` named `/usr/share/nginx/html/assets`:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts' 
- mountPath: /usr/share/nginx/html/assets
  name: efsvolume
- mountPath: /tmp
  name: tmp-volume
```

A PersistentVolume (PV) has been created automatically for the PersistentVolumeClaim (PVC) we had created in the previous step:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    assets/efs-claim                      efs-sc                  2m33s
```

Also describe the PersistentVolumeClaim (PVC) created:

```bash
$ kubectl describe pvc -n assets
Name:          efs-claim
Namespace:     assets
StorageClass:  efs-sc
Status:        Bound
Volume:        pvc-342a674d-b426-4214-b8b6-7847975ae121
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: efs.csi.aws.com
               volume.kubernetes.io/storage-provisioner: efs.csi.aws.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                 Age                From                                                                               Message
  ----    ------                 ----               ----                                                                               -------
  Normal  ExternalProvisioning   22m (x2 over 22m)  persistentvolume-controller                                                        waiting for a volume to be created, either by external provisioner "efs.csi.aws.com" or manually created by system administrator
  Normal  Provisioning           22m                efs.csi.aws.com_ip-10-42-11-246.ec2.internal_1b9196ea-2586-49a6-87dd-5ce1d78c4c0d  External provisioner is provisioning volume for claim "assets/efs-claim"
  Normal  ProvisioningSucceeded  22m                efs.csi.aws.com_ip-10-42-11-246.ec2.internal_1b9196ea-2586-49a6-87dd-5ce1d78c4c0d  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

Now create a new file `newproduct.png` under the assets directory in the first Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -c assets -- bash -c 'touch /usr/share/nginx/html/assets/newproduct.png'
```

And verify that the file now also exists in the second Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -c assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
newproduct.png <-----------
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
test.txt
wood_watch.jpg
```

Now as you can see even though we created a file through the first Pod the second Pod also has access to this file because of the shared EFS file system.
