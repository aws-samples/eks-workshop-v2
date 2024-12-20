---
title: Persistent Object Storage with Mountpoint for Amazon S3
sidebar_position: 30
---

In our previous steps, we prepared our environment by creating a staging directory for image objects, downloading image assets, and uploading them to our S3 bucket. We also installed and configured the Mountpoint for Amazon S3 CSI driver. Now we'll complete our objective of creating an image host application with **horizontal scaling** and **persistent storage** backed by Amazon S3 by attaching our pods to use the Persistent Volume (PV) provided by the Mountpoint for Amazon S3 CSI driver.

Let's start by creating a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and modifying the `assets` container in our deployment to mount this volume.

First, let's examine the `s3pvclaim.yaml` file to understand its parameters and configuration:

::yaml{file="manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml" paths="spec.accessModes,spec.mountOptions"}

1. `ReadWriteMany`: Allows the same S3 bucket to be mounted to multiple pods for read/write
2. `allow-delete`: Allows users to delete objects from the mounted bucket  
   `allow-other`: Allows users other than the owner to access the mounted bucket  
   `uid=999`: Sets User ID (UID) of files/directories in the mounted bucket to 999  
   `gid=999`: Sets Group ID (GID) of files/directories in the mounted bucket to 999  
   `region=us-west-2`: Sets the region of the S3 bucket to us-west-2

```kustomization
modules/fundamentals/storage/s3/deployment/deployment.yaml
Deployment/assets
```

Now let's apply this configuration and redeploy our application:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl apply -f-
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolume/s3-pv created
persistentvolumeclaim/s3-claim created
deployment.apps/assets configured
```

We'll monitor the deployment progress:

```bash
$ kubectl rollout status --timeout=180s deployment/assets -n assets
deployment "assets" successfully rolled out
```

Let's verify our volume mounts, noting the new `/mountpoint-s3` mount point:

```bash
$ kubectl get deployment -n assets -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

Examine our newly created PersistentVolume:

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    assets/s3-claim                  <unset>                          2m31s
```

Review the PersistentVolumeClaim details:

```bash
$ kubectl describe pvc -n assets
Name:          s3-claim
Namespace:     assets
StorageClass:
Status:        Bound
Volume:        s3-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       assets-9fbbbcd6f-c74vv
               assets-9fbbbcd6f-vb9jz
Events:        <none>
```

Verify our running pods:

```bash
$ kubectl get pods -n assets
NAME                     READY   STATUS    RESTARTS   AGE
assets-9fbbbcd6f-c74vv   1/1     Running   0          2m36s
assets-9fbbbcd6f-vb9jz   1/1     Running   0          2m38s
```

Let's examine our final deployment configuration with the Mountpoint for Amazon S3 CSI driver:

```bash
$ kubectl describe deployment -n assets
Name:                   assets
Namespace:              assets
[...]
  Containers:
   assets:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-assets:0.4.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  128Mi
    Requests:
      cpu:     128m
      memory:  128Mi
    Liveness:  http-get http://:8080/health.html delay=0s timeout=1s period=3s #success=1 #failure=3
    Environment Variables from:
      assets      ConfigMap  Optional: false
    Environment:  <none>
    Mounts:
      /mountpoint-s3 from mountpoint-s3 (rw)
      /tmp from tmp-volume (rw)
  Volumes:
   mountpoint-s3:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  s3-claim
    ReadOnly:   false
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

Now let's demonstrate the shared storage functionality. First, we'll list and create files in the first pod:

```bash
$ POD_1=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n assets -- bash -c 'ls /mountpoint-s3/'
chrono_classic.jpg
gentleman.jpg
pocket_watch.jpg
smart_2.jpg
wood_watch.jpg
$ kubectl exec --stdin $POD_1 -n assets -- bash -c 'touch /mountpoint-s3/divewatch.jpg'
```

To verify the persistence and sharing of our storage layer, let's check the second pod for the file we just created:

```bash
$ POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n assets -- bash -c 'ls /mountpoint-s3/'
chrono_classic.jpg
divewatch.jpg <-----------
gentleman.jpg
newproduct_1.jpg
pocket_watch.jpg
smart_2.jpg
wood_watch.jpg
```

Finally, let's create another file from the second pod and verify its presence in the S3 bucket:

```bash
$ POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n assets -- bash -c 'touch /mountpoint-s3/luxurywatch.jpg'
$ aws s3 ls $BUCKET_NAME
2024-10-14 19:29:05      98157 chrono_classic.jpg
2024-10-14 20:00:00          0 divewatch.jpg <----------- CREATED FROM POD 1
2024-10-14 19:29:05      58439 gentleman.jpg
2024-10-14 20:00:00          0 luxurywatch.jpg <----------- CREATED FROM POD 2
2024-10-14 19:29:05      58655 pocket_watch.jpg
2024-10-14 19:29:05      20795 smart_2.jpg
2024-10-14 19:29:05      43122 wood_watch.jpg
```

With that we've successfully demonstrated how we can use Mountpoint for Amazon S3 for persistent shared storage for workloads running on EKS.
