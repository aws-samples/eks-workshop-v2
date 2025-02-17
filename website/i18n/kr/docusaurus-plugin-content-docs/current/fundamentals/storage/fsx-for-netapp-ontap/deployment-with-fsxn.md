---
title: FSx를 이용한 동적 프로비저닝 for NetApp ONTAP
sidebar_position: 30
---
이제 Kubernetes용 FSxN 스토리지 클래스를 이해했으니 [영구 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 배포의 `assets` 컨테이너를 변경하여 생성된 볼륨을 마운트해보겠습니다.

먼저 `fsxnpvclaim.yaml` 파일을 검사하여 파일의 매개변수와 이전 단계에서 생성한 `fsxn-sc-nfs` 스토리지 클래스에서 5GB의 특정 스토리지 크기를 요청하는 내용을 확인해보세요:

```file
manifests/modules/fundamentals/storage/fsxn/deployment/fsxnpvclaim.yaml
```

또한 `assets` 서비스를 두 가지 방식으로 수정할 것입니다:

* `assets` 이미지가 저장되는 위치에 PVC 마운트
* FSxN 볼륨에 초기 이미지를 복사하는 [init 컨테이너](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) 추가

```kustomization
modules/fundamentals/storage/fsxn/deployment/deployment.yaml
Deployment/assets
```

다음 명령을 실행하여 변경사항을 적용할 수 있습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/deployment
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
persistentvolumeclaim/fsxn-nfs-claim created
deployment.apps/assets configured
$ kubectl rollout status --timeout=130s deployment/assets -n assets
```

이제 배포의 `volumeMounts`를 살펴보세요. `efsvolume`이라는 새로운 `Volume`이 `/usr/share/nginx/html/assets`라는 이름의 `volumeMounts`에 마운트된 것을 확인할 수 있습니다:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /usr/share/nginx/html/assets
  name: fsxnvolume
- mountPath: /tmp
  name: tmp-volume
```

이전 단계에서 생성한 PersistentVolumeClaim(PVC)을 위해 영구 볼륨(PV)이 자동으로 생성되었습니다:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-ceec6f39-8034-4b33-a4bc-c1b1370befd1   5Gi        RWX            Delete           Bound    assets/fsxn-nfs-claim                 fsxn-sc-nfs             173m
```

또한 생성된 PersistentVolumeClaim(PVC)을 설명합니다:

```bash
$ kubectl describe pvc -n assets
Name:          fsxn-nfs-claim
Namespace:     assets
StorageClass:  fsxn-sc-nfs
Status:        Bound
Volume:        pvc-ceec6f39-8034-4b33-a4bc-c1b1370befd1
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: csi.trident.netapp.io
               volume.kubernetes.io/storage-provisioner: csi.trident.netapp.io
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       assets-555dc4c9c9-g8hfs
               assets-555dc4c9c9-m6r2l
Events:        <none>
```

이제 첫 번째 Pod의 assets 디렉토리에 새 파일 `newproduct.png`를 생성합니다:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -- bash -c 'touch /usr/share/nginx/html/assets/newproduct.png'
```

그리고 이 파일이 두 번째 Pod에도 존재하는지 확인합니다:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin deployment/assets $POD_NAME \
  -n assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
newproduct.png <-----------
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
test.txt
wood_watch.jpg
```

이제 보시다시피 첫 번째 Pod를 통해 파일을 생성했지만 공유 FSxN 파일 시스템 덕분에 두 번째 Pod도 이 파일에 접근할 수 있습니다.
