---
title: Amazon S3용 마운트포인트 - 영구 오브젝트 스토리지
sidebar_position: 30
---
이전 단계에서 이미지 객체를 위한 스테이징 디렉토리를 생성하고, 이미지 자산을 다운로드하고, S3 버킷에 업로드하여 환경을 준비했습니다. 또한 `Mountpoint for Amazon S3` CSI 드라이버를 설치하고 구성했습니다. 이제 `Mountpoint for Amazon S3` CSI 드라이버가 제공하는 영구 볼륨(PV)을 사용하도록 Pod를 연결하여 Amazon S3가 지원하는 **수평적 확장**과 **영구 스토리지**를 갖춘 이미지 호스트 애플리케이션을 만드는 목표를 완료하겠습니다.

[영구 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 배포의 `assets` 컨테이너를 수정하여 이 볼륨을 마운트하는 것부터 시작하겠습니다.

먼저 `s3pvclaim.yaml` 파일을 살펴보고 매개변수와 구성을 이해해보겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml" paths="spec.accessModes,spec.mountOptions"}

1. `ReadWriteMany`: 동일한 S3 버킷을 여러 Pod에 읽기/쓰기용으로 마운트할 수 있음
2. `allow-delete`: 사용자가 마운트된 버킷에서 객체를 삭제할 수 있음
   `allow-other`: 소유자 외의 사용자가 마운트된 버킷에 접근할 수 있음
   `uid=999`: 마운트된 버킷의 파일/디렉토리의 사용자 ID(UID)를 `999`로 설정
   `gid=999`: 마운트된 버킷의 파일/디렉토리의 그룹 ID(GID)를 `999`로 설정
   `region=us-west-2`: S3 버킷의 리전을 `us-west-2`로 설정

```kustomization
modules/fundamentals/storage/s3/deployment/deployment.yaml
Deployment/assets
```

이제 이 구성을 적용하고 애플리케이션을 재배포해보겠습니다:

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

배포 진행 상황을 모니터링하겠습니다:

```bash
$ kubectl rollout status --timeout=180s deployment/assets -n assets
deployment "assets" successfully rolled out
```

새로운`/mountpoint-s3` 마운트 포인트를 포함한 볼륨 마운트를 확인해보겠습니다:

```bash
$ kubectl get deployment -n assets -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

새로 생성된 영구 볼륨을 검사해보겠습니다:

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    assets/s3-claim                  <unset>                          2m31s
```

영구 볼륨 클레임 세부 정보를 검토해보겠습니다:

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

실행 중인 Pod를 확인해보겠습니다:

```bash
$ kubectl get pods -n assets
NAME                     READY   STATUS    RESTARTS   AGE
assets-9fbbbcd6f-c74vv   1/1     Running   0          2m36s
assets-9fbbbcd6f-vb9jz   1/1     Running   0          2m38s
```

`Mountpoint for Amazon S3` CSI 드라이버가 포함된 최종 배포 구성을 살펴보겠습니다:

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

이제 공유 스토리지 기능을 시연해보겠습니다. 먼저 첫 번째 Pod에서 파일을 나열하고 생성해보겠습니다:

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

스토리지 계층의 지속성과 공유를 확인하기 위해 방금 생성한 파일이 두 번째 Pod에 있는지 확인해보겠습니다:

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

마지막으로 두 번째 Pod에서 다른 파일을 생성하고 S3 버킷에 존재하는지 확인해보겠습니다:

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

이로써 EKS에서 실행되는 워크로드를 위한 영구 공유 스토리지로 `Mountpoint for Amazon S3`를 어떻게 사용할 수 있는지 성공적으로 시연했습니다.
