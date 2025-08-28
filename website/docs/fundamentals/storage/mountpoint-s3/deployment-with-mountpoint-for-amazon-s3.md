---
title: Persistent object storage with S3
sidebar_position: 30
---

In our previous steps, we prepared our environment by creating a staging directory for image objects, downloading image assets, and uploading them to our S3 bucket. We also installed and configured the Mountpoint for Amazon S3 CSI driver. Now we'll complete our objective of creating an image host application with **horizontal scaling** and **persistent storage** backed by Amazon S3 by attaching our pods to use the Persistent Volume (PV) provided by the Mountpoint for Amazon S3 CSI driver.

Let's start by creating a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and modifying the `ui` container in our deployment to mount this volume.

First, let's examine the `s3pvclaim.yaml` file to understand its parameters and configuration:

::yaml{file="manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml" paths="spec.accessModes,spec.mountOptions,spec.csi.volumeAttributes.bucketName"}

1. `ReadWriteMany`: Allows the same S3 bucket to be mounted to multiple pods for read/write
2. `allow-delete`: Allows users to delete objects from the mounted bucket  
   `allow-other`: Allows users other than the owner to access the mounted bucket  
   `uid=`: Sets User ID (UID) of files/directories in the mounted bucket  
   `gid=`: Sets Group ID (GID) of files/directories in the mounted bucket  
   `region= $AWS_REGION`: Sets the region of the S3 bucket
3. `bucketName` specifies the S3 bucket name

```kustomization
modules/fundamentals/storage/s3/deployment/deployment.yaml
Deployment/ui
```

Now let's apply this configuration and redeploy our application:

```bash hook=s3-deployment
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl apply -f-
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolume/s3-pv created
persistentvolumeclaim/s3-claim created
deployment.apps/ui configured
```

We'll monitor the deployment progress:

```bash
$ kubectl rollout status --timeout=180s deployment/ui -n ui
deployment "ui" successfully rolled out
```

Let's verify our volume mounts, noting the new `/mountpoint-s3` mount point:

```bash
$ kubectl get deployment -n ui -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

Now let's examine our newly created PersistentVolume:

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    ui/s3-claim                      <unset>                          2m31s
```

Let's review the PersistentVolumeClaim details:

```bash
$ kubectl describe pvc -n ui
Name:          s3-claim
Namespace:     ui
StorageClass:
Status:        Bound
Volume:        s3-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       ui-9fbbbcd6f-c74vv
               ui-9fbbbcd6f-vb9jz
Events:        <none>
```

Let's verify our running pods:

```bash
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-9fbbbcd6f-c74vv    1/1     Running   0          2m36s
ui-9fbbbcd6f-vb9jz    1/1     Running   0          2m38s
```

Now let's examine our final deployment configuration with the Mountpoint for Amazon S3 CSI driver:

```bash
$ kubectl describe deployment -n ui
Name:                   ui
Namespace:              ui
[...]
  Containers:
   ui:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  128Mi
    Requests:
      cpu:     128m
      memory:  128Mi
    [...]
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

Now let's demonstrate the shared storage functionality. First, we'll list the current files in `/mountpoint-s3` through one of the UI component Pods:

```bash hook=sample-images
$ export POD_1=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /mountpoint-s3/'
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

We can see the list of images matches what we uploaded to the S3 bucket earlier. Now let's generate a new image called `placeholder.jpg` and add it to our S3 bucket through the same Pod:

```bash
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /mountpoint-s3/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

To verify the persistence and sharing of our storage layer, let's check for the file we just created using the second UI Pod:

```bash
$ export POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /mountpoint-s3/'
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

Finally, let's verify its presence in the S3 bucket:

```bash
$ aws s3 ls $BUCKET_NAME
2025-07-09 14:43:36     102950 1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
2025-07-09 14:43:36     118546 4f18544b-70a5-4352-8e19-0d070f46745d.jpg
2025-07-09 14:43:36     147820 631a3db5-ac07-492c-a994-8cd56923c112.jpg
2025-07-09 14:43:36     100117 79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
2025-07-09 14:43:36     106911 8757729a-c518-4356-8694-9e795a9b3237.jpg
2025-07-09 14:43:36     113010 87e89b11-d319-446d-b9be-50adcca5224a.jpg
2025-07-09 14:43:36     171045 a1258cd2-176c-4507-ade6-746dab5ad625.jpg
2025-07-09 14:43:36     170438 cc789f85-1476-452a-8100-9e74502198e0.jpg
2025-07-09 14:43:36      97592 d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
2025-07-09 14:43:36     169246 d3104128-1d14-4465-99d3-8ab9267c687b.jpg
2025-07-09 14:43:36     151884 d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
2025-07-09 14:43:36     134344 d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
2025-07-09 15:10:27      10024 placeholder.jpg         <----------------
```

Now we can confirm the image is available through the UI:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

Visit the URL in your browser:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('./assets/placeholder.jpg').default}/>
</Browser>

With that, we've successfully demonstrated how we can use Mountpoint for Amazon S3 for persistent shared storage for workloads running on EKS.
