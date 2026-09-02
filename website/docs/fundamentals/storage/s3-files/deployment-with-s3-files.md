---
title: Static provisioning using S3 Files
sidebar_position: 30
---

Now that we understand the S3 Files storage class for Kubernetes and why S3 Files uses static provisioning, let's statically provision a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for our pre-created S3 file system and modify the UI component to mount it.

An S3 file system has been provisioned for us, linked to an S3 bucket with versioning enabled. The file system includes mount targets and the required security group that includes an inbound rule allowing NFS traffic on port 2049. Let's get its ID which we'll need for the static `PersistentVolume`:

```bash
$ echo $S3_FILES_ID
fs-0123456789abcdef0
```

With static provisioning we define three objects that work as a set:

1. A `StorageClass` (`s3-files-sc`) with no parameters, used only to bind the volume and claim
2. A `PersistentVolume` (`s3-files-pv`) that points directly at our existing S3 file system
3. A `PersistentVolumeClaim` (`s3-files-claim`) that binds to that specific `PersistentVolume`

The [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) for static provisioning acts only as a binding label between our `PersistentVolume` and `PersistentVolumeClaim` — it deliberately has **no parameters**, so the driver never tries to provision anything on demand:

::yaml{file="manifests/modules/fundamentals/storage/s3-files/pv/s3filesstorageclass.yaml" paths="provisioner"}

1. Set the `provisioner` parameter to `efs.csi.aws.com` — the same provisioner used for EFS, since S3 Files uses the EFS CSI driver
2. Note that there are no `parameters`: unlike dynamic provisioning, we are not asking the driver to create a file system or access point

Now let's examine the `PersistentVolume` and `PersistentVolumeClaim`:

::yaml{file="manifests/modules/fundamentals/storage/s3-files/pv/s3filespv.yaml" paths="spec.csi.driver,spec.csi.volumeHandle,spec.persistentVolumeReclaimPolicy"}

1. The `csi.driver` is `efs.csi.aws.com`, the EFS CSI driver that also serves S3 Files
2. The `volumeHandle` uses the `s3files:` prefix followed by our file system ID (for example `s3files:fs-0123456789abcdef0`). This prefix is what tells the driver to mount an S3 file system rather than an EFS file system. The `$S3_FILES_ID` environment variable is injected here.
3. The reclaim policy is `Retain`, so deleting the claim does not delete the underlying S3 file system or its data

The `PersistentVolumeClaim` sets `volumeName: s3-files-pv` so it binds to exactly the volume we defined, rather than triggering any dynamic provisioning.

Apply the kustomization, which creates the `StorageClass`, `PersistentVolume`, and `PersistentVolumeClaim`:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3-files/pv \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/s3-files-sc created
persistentvolume/s3-files-pv created
persistentvolumeclaim/s3-files-claim created
```

Because the `PersistentVolume` was created ahead of time, it binds to our claim immediately:

```bash
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   REASON   AGE
s3-files-pv   5Gi        RWX            Retain           Bound    ui/s3-files-claim    s3-files-sc             10s
```

Let's examine the details of our PersistentVolumeClaim (PVC):

```bash
$ kubectl describe pvc s3-files-claim -n ui
Name:          s3-files-claim
Namespace:     ui
StorageClass:  s3-files-sc
Status:        Bound
Volume:        s3-files-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```

Notice the claim is `Bound` to the `s3-files-pv` volume we statically defined — no external provisioner had to create anything.

Now we'll update the UI component to reference the S3 Files PVC:

```kustomization
modules/fundamentals/storage/s3-files/deployment/deployment.yaml
Deployment/ui
```

This patch also adds a small `fix-permissions` init container. The `ui` container runs as the non-root user `1000`, but the S3 Files volume is mounted owned by `root`. Because S3 Files uses an NFS-based file system, the pod's `fsGroup` setting does not automatically change the ownership of the mounted volume the way it does for block storage like Amazon EBS. The init container runs as `root` and `chown`s the mount to user `1000` before the `ui` container starts, so the application can write to `/s3files`. Without it, writes such as the one later in this lab would fail with a permission error.

Apply these changes with the following command:

```bash hook=s3-files-deployment
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/s3-files/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

Let's examine the `volumeMounts` in the deployment. Notice that our new volume named `s3filesvolume` is mounted at `/s3files`:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /s3files
  name: s3filesvolume
- mountPath: /tmp
  name: tmp-volume
```

At this point, the S3 file system is successfully mounted but currently empty:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /s3files/'
```

Let's use a [Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) to populate the S3 Files volume with images:

```bash
$ export PVC_NAME="s3-files-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

Now let's demonstrate the shared storage functionality by listing the current files in `/s3files` through one of the UI component Pods:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /s3files/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
```

Because S3 Files automatically synchronizes data between the file system and the S3 bucket, we can verify that the images are also present in the underlying S3 bucket:

```bash
$ aws s3 ls $S3_FILES_BUCKET_NAME
                           PRE /
2025-07-09 14:43:36     102950 1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
2025-07-09 14:43:36     118546 4f18544b-70a5-4352-8e19-0d070f46745d.jpg
[...]
```

The `PRE /` entry is a zero-byte object that S3 Files uses to represent the file system's root directory in the bucket — it is created when the `fix-permissions` init container sets ownership on the mount root. It is a normal part of how S3 Files maps a POSIX file system onto S3 objects, not an error, and it does not affect the image files. All of the image files appear alongside it at the top level of the bucket.

To further demonstrate the shared storage capabilities, let's create a new image called `placeholder.jpg` and add it to the S3 Files volume through the first Pod:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /s3files/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

Now we'll verify that the second UI Pod can access this newly created file, demonstrating the shared nature of our S3 Files storage:

```bash hook=sample-images
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /s3files/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
placeholder.jpg      <----------------
```

As you can see, even though we created the file through the first Pod, the second Pod has immediate access to it because they're both accessing the same shared S3 file system.

S3 Files will also automatically synchronize this new file back to the underlying S3 bucket, making it accessible through the S3 API as well.

Finally, let's confirm that the image is accessible through the UI service:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

Visit the URL in your browser:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/s3-files/placeholder.jpg').default}/>
</Browser>

We've successfully demonstrated how Amazon S3 Files provides persistent shared storage for workloads running on Amazon EKS. This solution combines the simplicity and performance of a file system with the scalability and durability of Amazon S3, allowing multiple pods to read from and write to the same storage volume simultaneously while keeping data synchronized with your S3 bucket.
