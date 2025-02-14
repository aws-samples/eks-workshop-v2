---
title: EFS를 이용한 동적 프로비저닝
sidebar_position: 30
---
이제 Kubernetes용 EFS 스토리지 클래스를 이해했으니, [영구 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 `assets` 컨테이너 배포를 수정하여 이 볼륨을 마운트해보겠습니다.

먼저, 이전에 생성한 `efs-sc` 스토리지 클래스에서 5GB의 스토리지를 요청하는 PersistentVolumeClaim을 정의하는 `efspvclaim.yaml` 파일을 살펴보겠습니다:

```file
manifests/modules/fundamentals/storage/efs/deployment/efspvclaim.yaml
```

`assets` 서비스를 다음과 같이 업데이트하겠습니다:

* assets 이미지가 저장되는 위치에 PVC 마운트
* EFS 볼륨에 초기 이미지를 복사하는 [init 컨테이너](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) 포함

```kustomization
modules/fundamentals/storage/efs/deployment/deployment.yaml
Deployment/assets
```

다음 명령으로 이러한 변경사항을 적용합니다:

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

배포의 `volumeMounts`를 살펴보겠습니다. `efsvolume`이라는 새로운 볼륨이 `/usr/share/nginx/html/assets`에 마운트된 것을 확인하세요:

```bash
$ kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /usr/share/nginx/html/assets
  name: efsvolume
- mountPath: /tmp
  name: tmp-volume
```

PersistentVolumeClaim(PVC)을 충족하기 위해 영구 볼륨(PV)이 자동으로 생성되었습니다:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    assets/efs-claim                      efs-sc                  2m33s
```

PersistentVolumeClaim(PVC)의 세부 정보를 살펴보겠습니다:

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

공유 스토리지 기능을 시연하기 위해 첫 번째 Pod의 assets 디렉토리에 새 파일 `newproduct.png`를 생성해보겠습니다:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -c assets -- bash -c 'touch /usr/share/nginx/html/assets/newproduct.png'
```

이제 이 파일이 두 번째 Pod에 존재하는지 확인해보겠습니다:

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

보시다시피, 첫 번째 Pod를 통해 파일을 생성했지만 두 번째 Pod도 동일한 EFS 파일 시스템을 사용하고 있기 때문에 즉시 접근할 수 있습니다.
