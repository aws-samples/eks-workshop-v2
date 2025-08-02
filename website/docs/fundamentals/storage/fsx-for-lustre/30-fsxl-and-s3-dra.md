---
title: FSx for Lustre with S3 DRA
sidebar_position: 30
---

In our previous steps, we prepared our environment by creating a staging directory for image objects, downloading image assets, and uploading them to our S3 bucket that is used as the DRA for our FSx for Lustre file system. We also installed and configured the FSx for Lustre CSI driver. Now we'll complete our objective of creating an image host application with **horizontal scaling** and **persistent storage** backed by Amazon FSx for Lustre by attaching our pods to use the Persistent Volume (PV) provided by the Amazon FSx for Lustre CSI driver.

Let's start by creating a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and modifying the `assets` container in our deployment to mount this volume.

First, let's examine the `fsxpvclaim.yaml` file to understand its parameters and configuration:

::yaml{file="manifests/modules/fundamentals/storage/fsxl/deployment/fsxpvclaim.yaml"}

```kustomization
modules/fundamentals/storage/fsxl/deployment/deployment.yaml
Deployment/assets
```

Now let's apply this configuration and redeploy our application:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/deployment \
  | envsubst | kubectl apply -f-
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolume/fsx-pv created
persistentvolumeclaim/fsx-claim created
deployment.apps/assets configured
```

We'll monitor the deployment progress:

```bash
$ kubectl rollout status --timeout=120s deployment/assets -n assets
Waiting for deployment "assets" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "assets" rollout to finish: 1 old replicas are pending termination...
deployment "assets" successfully rolled out
```

Let's verify our volume mounts, noting the new `/fsx-lustre` mount point:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /fsx-lustre
  name: fsx-lustre
- mountPath: /tmp
  name: tmp-volume
```

Examine our newly created PersistentVolume:

```bash
$ kubectl get pv
AME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
fsx-pv   1200Gi     RWX            Retain           Bound    assets/fsx-claim                  <unset>                          56s
```

Review the PersistentVolumeClaim details:

```bash
$ kubectl describe pvc -n assets
Name:          fsx-claim
Namespace:     assets
StorageClass:
Status:        Bound
Volume:        fsx-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1200Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       assets-654d866dc8-hrcml
               assets-654d866dc8-w8thw
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
      /fsx-lustre from fsx-lustre (rw)
      /tmp from tmp-volume (rw)
  Volumes:
   fsx-lustre:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  fsx-claim
    ReadOnly:   false
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

Now let's demonstrate the shared storage functionality. First, we'll list the files in the first pod:

```bash
$ POD_1=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n assets -- bash -c 'ls /fsx-lustre/'
chrono_classic.jpg
gentleman.jpg
pocket_watch.jpg
smart_2.jpg
wood_watch.jpg
```

Now let's create a new file called `divewatch.png` and upload it into our DRA S3 bucket that backs the FSx for Lustre PVC:

```bash
$ touch divewatch.png && aws s3 cp divewatch.png s3://$BUCKET_NAME/
upload: ./divewatch.png to s3://eks-workshop-s3-data20250619213912331100000003/divewatch.png
```

We can now verify that the new file `divewatch.png` is visible from our first pod:

```bash
$ kubectl exec --stdin $POD_1 -n assets -- bash -c 'ls /fsx-lustre/'
chrono_classic.jpg
divewatch.png <-----------
gentleman.jpg
pocket_watch.jpg
smart_2.jpg
wood_watch.jpg
```

To verify the persistence and sharing of our storage layer, let's check the second pod for the file we just created:

```bash
$ POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n assets -- bash -c 'ls /fsx-lustre/'
chrono_classic.jpg
divewatch.png <-----------
gentleman.jpg
pocket_watch.jpg
smart_2.jpg
wood_watch.jpg
```

With that we've successfully demonstrated how we can use Mountpoint for Amazon S3 for persistent shared storage for workloads running on EKS.