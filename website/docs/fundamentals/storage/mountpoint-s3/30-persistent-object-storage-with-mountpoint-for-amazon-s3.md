---
title: Persistent Object Storage with Mountpoint for Amazon S3
sidebar_position: 30
---

Remember that our end goal is to have an image host application that **scales horozontally** and has **persistent storage** backed by Amazon S3. In the previous steps we created a staging directory for our image objects, then we downloaded the image assets into the staging directory and uploaded them into our S3 bucket. Finally, we installed the Mountpoint for Amazon S3 CSI driver and added it to our environment. We now need to attach our pods to use this PV provided by the Mountpoint for Amazon S3 CSI driver.

Let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the `assets` container on the assets deployment to mount the Volume created.

First inspect the `s3pvclaim.yaml` file to see the parameters in the file and the claim:

```file
manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml
```

In particular, notice the comments in the mountOptions section:

- `allow-delete`: Allows users to delete objects from the mounted bucket
- `allow-other`: Allows users other than the owner to access the mounted bucket
- `uid=999`: Sets the User ID (UID) of the files and directories in the mounted bucket to 999
- `gid=999`: Sets the Group ID (GID) of the files and directories in the mounted bucket to 999
- `region us-west-2`: Sets the region of the bucket to us-west-2

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

We can view our PersistentVolume (PV) assets, PersistentVolumeClaim (PVC) assets, and pod assets with `kubectl`:

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    assets/s3-claim                  <unset>                          2m31s

$ kubectl get pvc -n assets
AME       STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s3-claim   Bound    s3-pv    1Gi        RWX                           <unset>                 6m41s

$ kubectl get pods -n assets
NAME                     READY   STATUS    RESTARTS   AGE
assets-9fbbbcd6f-26jrq   1/1     Running   0          6m57s
assets-9fbbbcd6f-lb46c   1/1     Running   0          6m55s
```

Finally, let's take a look at our final deployment with the Mountpoint for Amazon S3 CSI driver:

```bash
$ kubectl describe deployment -n assets
Name:                   assets
Namespace:              assets
CreationTimestamp:      Mon, 14 Oct 2024 19:19:47 +0000
Labels:                 app.kubernetes.io/created-by=eks-workshop
                        app.kubernetes.io/type=app
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app.kubernetes.io/component=service,app.kubernetes.io/instance=assets,app.kubernetes.io/name=assets
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:           app.kubernetes.io/component=service
                    app.kubernetes.io/created-by=eks-workshop
                    app.kubernetes.io/instance=assets
                    app.kubernetes.io/name=assets
  Annotations:      prometheus.io/path: /metrics
                    prometheus.io/port: 8080
                    prometheus.io/scrape: true
  Service Account:  assets
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
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  assets-784b5f5656 (0/0 replicas created)
NewReplicaSet:   assets-9fbbbcd6f (2/2 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  20m    deployment-controller  Scaled up replica set assets-784b5f5656 to 1
  Normal  ScalingReplicaSet  15m    deployment-controller  Scaled up replica set assets-784b5f5656 to 2 from 1
  Normal  ScalingReplicaSet  7m21s  deployment-controller  Scaled up replica set assets-9fbbbcd6f to 1
  Normal  ScalingReplicaSet  7m19s  deployment-controller  Scaled down replica set assets-784b5f5656 to 1 from 2
  Normal  ScalingReplicaSet  7m19s  deployment-controller  Scaled up replica set assets-9fbbbcd6f to 2 from 1
  Normal  ScalingReplicaSet  7m17s  deployment-controller  Scaled down replica set assets-784b5f5656 to 0 from 1
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
