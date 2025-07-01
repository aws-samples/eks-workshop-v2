---
title: Dynamic provisioning using FSx for OpenZFS
sidebar_position: 30
---

With the Amazon FSx for OpenZFS CSI driver installed you can now create the [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) for the data volume.

When the FSx for OpenZFS file system was created by the workshop, a root volume for the file system was created as well. It is best practice not to store data in the root volume, but instead create separate child volumes of the root and store data in them. Since the root volume was created by the workshop, you can obtain its volume ID and create a child volume below it within the file system.

Run the following to obtain the root volume ID and set it to an environment variable we'll inject into the volume StorageClass using Kustomize:

```bash
$ export ROOT_VOL_ID=$(aws fsx describe-file-systems --file-system-id $FSXZ_FS_ID | jq -r '.FileSystems[] | .OpenZFSConfiguration.RootVolumeId')
```

Using Kustomize, we'll create the volume storage class and inject the `ROOT_VOL_ID`, `VPC_CIDR`, and `EKS_CLUSTER_NAME` environment variables into the `ParentVolumeId`, `NfsExports`, and `Name` parameters respectively:

```file
manifests/modules/fundamentals/storage/fsxz/storageclass-vol/fsxz-vol-sc.yaml
```

Apply the kustomization:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxz/storageclass-vol \
  | envsubst | kubectl apply -f-
```

Let's examine the volume StorageClass by running the command below. Note that it uses the FSx OpenZFS CSI driver as the provisioner and is updated with the VPC CIDR and Root Volume ID we exported earlier:

```bash
$ kubectl describe sc fsxz-vol-sc
Name:            fsxz-vol-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":false,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxz-vol-sc"},"mountOptions":["nfsvers=4.1","rsize=1048576","wsize=1048576","timeo=600","nconnect=16"],"parameters":{"CopyTagsToSnapshots":"false","DataCompressionType":"\"LZ4\"","NfsExports":"[{\"ClientConfigurations\": [{\"Clients\": \"10.42.0.0/16\", \"Options\": [\"rw\",\"crossmnt\",\"no_root_squash\"]}]}]","OptionsOnDeletion":"[\"DELETE_CHILD_VOLUMES_AND_SNAPSHOTS\"]","ParentVolumeId":"\"fsvol-0efa720c2c77956a4\"","ReadOnly":"false","RecordSizeKiB":"128","ResourceType":"volume","Tags":"[{\"Key\": \"Name\", \"Value\": \"eks-workshop-data\"}]"},"provisioner":"fsx.openzfs.csi.aws.com","reclaimPolicy":"Delete"}

Provisioner:           fsx.openzfs.csi.aws.com
Parameters:            CopyTagsToSnapshots=false,DataCompressionType="LZ4",NfsExports=[{"ClientConfigurations": [{"Clients": "10.42.0.0/16", "Options": ["rw","crossmnt","no_root_squash"]}]}],OptionsOnDeletion=["DELETE_CHILD_VOLUMES_AND_SNAPSHOTS"],ParentVolumeId="fsvol-0efa720c2c77956a4",ReadOnly=false,RecordSizeKiB=128,ResourceType=volume,Tags=[{"Key": "Name", "Value": "eks-workshop-data"}]
AllowVolumeExpansion:  False
MountOptions:
  nfsvers=4.1
  rsize=1048576
  wsize=1048576
  timeo=600
  nconnect=16
ReclaimPolicy:      Delete
VolumeBindingMode:  Immediate
Events:             <none>
```

Run the following to create the volume PVC and deploy the volume based on the StorageClass:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxz/deployment-vol
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolumeclaim/fsxz-vol-pvc created
deployment.apps/assets configured
```

Run the following to view the progress of the volume PVC deployment and creation of the volume on the FSx for OpenZFS file system. This will typically take less than 5 minutes and when complete, the deployment will show as successfully rolled out:

```bash timeout=660
$ kubectl rollout status --timeout=600s deployment/assets -n assets
Waiting for deployment "assets" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "assets" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "assets" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "assets" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "assets" rollout to finish: 1 old replicas are pending termination...
deployment "assets" successfully rolled out
```

Let's examine the `volumeMounts` in the deployment. Notice our new volume named `fsxz-vol` is mounted at `/usr/share/nginx/html/assets`:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /usr/share/nginx/html/assets
  name: fsxz-vol
- mountPath: /tmp
  name: tmp-volume
```

A PersistentVolume (PV) has been automatically created to fulfill our PersistentVolumeClaim (PVC):

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-de67d22d-040d-4898-b0ce-0b3139a227c1   1Gi        RWX            Delete           Bound    assets/fsxz-vol-pvc   fsxz-vol-sc    <unset>                          27s                       31s
```

Let's examine the details of our PersistentVolumeClaim (PVC):

```bash
$ kubectl describe pvc -n assets
Name:          fsxz-vol-pvc
Namespace:     assets
StorageClass:  fsxz-vol-sc
Status:        Bound
Volume:        pvc-de67d22d-040d-4898-b0ce-0b3139a227c1
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: fsx.openzfs.csi.aws.com
               volume.kubernetes.io/storage-provisioner: fsx.openzfs.csi.aws.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       assets-8bf5b5bfd-2gcc6
               assets-8bf5b5bfd-lw9qp
Events:
  Type    Reason                 Age                  From                                                                                                      Message
  ----    ------                 ----                 ----                                                                                                      -------
  Normal  Provisioning           2m13s                fsx.openzfs.csi.aws.com_fsx-openzfs-csi-controller-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  External provisioner is provisioning volume for claim "assets/fsxz-vol-pvc"
  Normal  ExternalProvisioning   69s (x7 over 2m13s)  persistentvolume-controller                                                                               Waiting for a volume to be created either by the external provisioner 'fsx.openzfs.csi.aws.com' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
  Normal  ProvisioningSucceeded  57s                  fsx.openzfs.csi.aws.com_fsx-openzfs-csi-controller-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  Successfully provisioned volume pvc-de67d22d-040d-4898-b0ce-0b3139a227c1
```

To demonstrate the shared storage functionality, let's create a new file `new_gmt_watch.png` in the assets directory of the first Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -c assets -- bash -c 'touch /usr/share/nginx/html/assets/new_gmt_watch.png'
$ kubectl exec --stdin $POD_NAME \
  -n assets -c assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
new_gmt_watch.png  <-----------
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
wood_watch.jpg
```

Now verify that this file exists in the second Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -c assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
new_gmt_watch.png  <-----------
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
test.txt
wood_watch.jpg
```

As you can see, even though we created the file through the first Pod, the second Pod has immediate access to it because they're both using the same Amazon FSx for OpenZFS file system.
