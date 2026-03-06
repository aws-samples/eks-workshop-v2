---
title: S3를 사용한 영구 객체 스토리지
sidebar_position: 30
tmdTranslationSourceHash: a2905c137570577f1a4417aa32e22e51
---

이전 단계에서 이미지 객체를 위한 스테이징 디렉터리를 생성하고, 이미지 자산을 다운로드하고, S3 버킷에 업로드하여 환경을 준비했습니다. 또한 Mountpoint for Amazon S3 CSI 드라이버를 설치하고 구성했습니다. 이제 Mountpoint for Amazon S3 CSI 드라이버가 제공하는 Persistent Volume(PV)을 사용하도록 Pod를 연결하여 **수평 스케일링**과 Amazon S3로 백업되는 **영구 스토리지**를 갖춘 이미지 호스트 애플리케이션을 생성하는 목표를 완료하겠습니다.

먼저 [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 배포에서 `ui` 컨테이너를 수정하여 이 볼륨을 마운트하겠습니다.

먼저 `s3pvclaim.yaml` 파일을 검토하여 매개변수와 구성을 이해하겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml" paths="spec.accessModes,spec.mountOptions,spec.csi.volumeAttributes.bucketName"}

1. `ReadWriteMany`: 동일한 S3 버킷을 여러 Pod에 읽기/쓰기용으로 마운트할 수 있습니다
2. `allow-delete`: 사용자가 마운트된 버킷에서 객체를 삭제할 수 있습니다  
   `allow-other`: 소유자 이외의 사용자가 마운트된 버킷에 액세스할 수 있습니다  
   `uid=`: 마운트된 버킷의 파일/디렉터리의 사용자 ID(UID)를 설정합니다  
   `gid=`: 마운트된 버킷의 파일/디렉터리의 그룹 ID(GID)를 설정합니다  
   `region= $AWS_REGION`: S3 버킷의 리전을 설정합니다
3. `bucketName`은 S3 버킷 이름을 지정합니다

```kustomization
modules/fundamentals/storage/s3/deployment/deployment.yaml
Deployment/ui
```

이제 이 구성을 적용하고 애플리케이션을 재배포하겠습니다:

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

배포 진행 상황을 모니터링하겠습니다:

```bash
$ kubectl rollout status --timeout=180s deployment/ui -n ui
deployment "ui" successfully rolled out
```

새로운 `/mountpoint-s3` 마운트 포인트에 주목하여 볼륨 마운트를 확인해보겠습니다:

```bash
$ kubectl get deployment -n ui -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

이제 새로 생성된 PersistentVolume을 살펴보겠습니다:

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    ui/s3-claim                      <unset>                          2m31s
```

PersistentVolumeClaim 세부 정보를 검토하겠습니다:

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

실행 중인 Pod를 확인해보겠습니다:

```bash
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-9fbbbcd6f-c74vv    1/1     Running   0          2m36s
ui-9fbbbcd6f-vb9jz    1/1     Running   0          2m38s
```

이제 Mountpoint for Amazon S3 CSI 드라이버가 적용된 최종 배포 구성을 살펴보겠습니다:

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

이제 공유 스토리지 기능을 실제로 확인해보겠습니다. 먼저 UI 컴포넌트 Pod 중 하나를 통해 `/mountpoint-s3`의 현재 파일 목록을 확인하겠습니다:

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

이미지 목록이 이전에 S3 버킷에 업로드한 것과 일치하는 것을 확인할 수 있습니다. 이제 `placeholder.jpg`라는 새 이미지를 생성하고 동일한 Pod를 통해 S3 버킷에 추가하겠습니다:

```bash
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /mountpoint-s3/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

스토리지 계층의 영구성과 공유를 확인하기 위해 두 번째 UI Pod를 사용하여 방금 생성한 파일을 확인해보겠습니다:

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

마지막으로 S3 버킷에 있는지 확인하겠습니다:

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

이제 UI를 통해 이미지를 사용할 수 있는지 확인할 수 있습니다:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

브라우저에서 URL을 방문하세요:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/mountpoint-s3/placeholder.jpg').default}/>
</Browser>

이로써 EKS에서 실행되는 워크로드를 위한 영구 공유 스토리지로 Mountpoint for Amazon S3를 사용하는 방법을 성공적으로 시연했습니다.

