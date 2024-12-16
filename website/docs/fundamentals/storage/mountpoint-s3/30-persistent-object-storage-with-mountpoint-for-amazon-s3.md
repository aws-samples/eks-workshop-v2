---
title: Persistent Object Storage with Mountpoint for Amazon S3
sidebar_position: 30
---

Remember that our end goal is to have an image host application that **scales horizontally** and has **persistent storage** backed by Amazon S3. In the previous steps we created a staging directory for our image objects, then we downloaded the image assets into the staging directory and uploaded them into our S3 bucket. Finally, we installed the Mountpoint for Amazon S3 CSI driver and added it to our environment. We now need to attach our pods to use this PV provided by the Mountpoint for Amazon S3 CSI driver.

Let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the `assets` container on the assets deployment to mount the Volume created.

First inspect the `s3pvclaim.yaml` file to see the parameters in the file and the claim:

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

Let's apply this Kustomization and re-deploy. This step will take a few minutes:

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

We can monitor the progress of the roll-out and wait for it to finish:

```bash
$ kubectl rollout status --timeout=130s deployment/assets -n assets
deployment "assets" successfully rolled out
```

View all volume mounts on deployment, note `/mountpoint-s3`

```bash
$ kubectl get deployment -n assets -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

We can view our PersistentVolume (PV):

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    assets/s3-claim                  <unset>                          2m31s
```

Let's examine the details of our PersistentVolumeClaim (PVC):

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

We can also see the running pods in the deployment:

```bash
$ kubectl get pods -n assets
NAME                     READY   STATUS    RESTARTS   AGE
assets-9fbbbcd6f-c74vv   1/1     Running   0          2m36s
assets-9fbbbcd6f-vb9jz   1/1     Running   0          2m38s
```

Finally, let's take a look at our final deployment with the Mountpoint for Amazon S3 CSI driver:

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

Let's go into first pod and list files at `/mountpoint-s3`. Since we have our S3 bucket mounted with the Mountpoint for Amazon S3 CSI driver, we can create a new image inside of the mounted S3 bucket too:

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

We know that this is a persistent storage layer that is mounted by all of the pods, so let's go into the second pod and view the file that we created from the first pod:

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

Since this is a persistent storage layer that is mounted by all of the pods in our cluster, we also create another image file on this pod and view the object with `aws s3 ls`:

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