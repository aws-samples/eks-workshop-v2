---
title: Dynamic provisioning using EFS
sidebar_position: 30
---

Now that we understand the EFS storage class for Kubernetes, let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and modify the `assets` container deployment to mount this volume.

First, let's examine the `efspvclaim.yaml` file which defines a PersistentVolumeClaim requesting 5GB of storage from the `efs-sc` storage class we created earlier:

```file
manifests/modules/fundamentals/storage/efs/deployment/efspvclaim.yaml
```

We'll update the assets service to:

- Mount the PVC at the location where assets images are stored
- Include an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that copies the initial images to the EFS volume

```kustomization
modules/fundamentals/storage/efs/deployment/deployment.yaml
Deployment/assets
```

Apply these changes with the following command:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/efs/deployment
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolumeclaim/efs-claim created
deployment.apps/assets configured
$ kubectl rollout status --timeout=130s deployment/assets -n assets
```

Let's examine the `volumeMounts` in the deployment. Notice that our new volume named `efsvolume` is mounted at `/usr/share/nginx/html/assets`:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /usr/share/nginx/html/assets
  name: efsvolume
- mountPath: /tmp
  name: tmp-volume
```

A PersistentVolume (PV) has been automatically created to fulfill our PersistentVolumeClaim (PVC):

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    assets/efs-claim                      efs-sc                  2m33s
```

Let's examine the details of our PersistentVolumeClaim (PVC):

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
  Type    Reason                 Age   From                                                                                      Message
  ----    ------                 ----  ----                                                                                      -------
  Normal  ExternalProvisioning   34s   persistentvolume-controller                                                               waiting for a volume to be created, either by external provisioner "efs.csi.aws.com" or manually created by system administrator
  Normal  Provisioning           34s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  External provisioner is provisioning volume for claim "assets/efs-claim"
  Normal  ProvisioningSucceeded  33s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

To demonstrate the shared storage functionality, let's create a new file `newproduct.png` in the assets directory of the first Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -c assets -- bash -c 'touch /usr/share/nginx/html/assets/newproduct.png'
```

Now verify that this file exists in the second Pod:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
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

As you can see, even though we created the file through the first Pod, the second Pod has immediate access to it because they're both using the same EFS file system.
