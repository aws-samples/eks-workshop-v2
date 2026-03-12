---
title: FSx for OpenZFS를 사용한 동적 프로비저닝
sidebar_position: 30
tmdTranslationSourceHash: 53fcfdb5bdb801647660e1719940d4c5
---

이제 Kubernetes용 FSx for OpenZFS 스토리지 클래스를 이해했으므로 [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 UI 컴포넌트를 수정하여 이 볼륨을 마운트해보겠습니다.

먼저 `fsxzpvcclaim.yaml` 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/fsxz/deployment/fsxzpvcclaim.yaml" paths="kind,spec.storageClassName,spec.resources.requests.storage"}

1. 정의되는 리소스는 PersistentVolumeClaim입니다
2. 이전에 생성한 `fsxz-vol-sc` 스토리지 클래스를 참조합니다
3. 1GB의 스토리지를 요청합니다

이제 UI 컴포넌트를 업데이트하여 FSx for OpenZFS PVC를 참조하도록 하겠습니다:

```kustomization
modules/fundamentals/storage/fsxz/deployment/deployment.yaml
Deployment/ui
```

다음 명령으로 이러한 변경 사항을 적용합니다:

```bash wait=30
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxz/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolumeclaim/fsxz-claim created
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

배포의 `volumeMounts`를 살펴보겠습니다. `fsxzvolume`이라는 새로운 볼륨이 `/fsxz`에 마운트된 것을 확인할 수 있습니다:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /fsxz
  name: fsxzvolume
- mountPath: /tmp
  name: tmp-volume
```

PersistentVolumeClaim(PVC)을 충족하기 위해 PersistentVolume(PV)이 자동으로 생성되었습니다:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   1Gi        RWX            Delete           Bound    ui/fsxz-claim                      fsxz-vol-sc                  2m33s
```

PersistentVolumeClaim(PVC)의 세부 정보를 살펴보겠습니다:

```bash
$ kubectl describe pvc -n ui
Name:          fsxz-claim
Namespace:     ui
StorageClass:  fsxz-vol-sc
Status:        Bound
Volume:        pvc-342a674d-b426-4214-b8b6-7847975ae121
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: fsx.openzfs.csi.aws.com
               volume.kubernetes.io/storage-provisioner: fsx.openzfs.csi.aws.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                 Age   From                                                                                      Message
  ----    ------                 ----  ----                                                                                      -------
  Normal  ExternalProvisioning   34s   persistentvolume-controller                                                               waiting for a volume to be created, either by external provisioner "fsx.openzfs.csi.aws.com" or manually created by system administrator
  Normal  Provisioning           34s   fsx.openzfs.csi.aws.com_fsx-openzfs-csi-controller-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  External provisioner is provisioning volume for claim "ui/fsxz-claim"
  Normal  ProvisioningSucceeded  33s   fsx.openzfs.csi.aws.com_fsx-openzfs-csi-controller-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

이 시점에서 FSx for OpenZFS 파일 시스템이 성공적으로 마운트되었지만 현재는 비어 있습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxz/'
```

[Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)을 사용하여 FSx for OpenZFS 볼륨을 이미지로 채워보겠습니다:

```bash
$ export PVC_NAME="fsxz-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

이제 UI 컴포넌트 Pod 중 하나를 통해 `/fsxz`의 현재 파일을 나열하여 공유 스토리지 기능을 시연해보겠습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxz/'
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

공유 스토리지 기능을 추가로 시연하기 위해 `placeholder.jpg`라는 새 이미지를 생성하고 첫 번째 Pod를 통해 FSx for OpenZFS 볼륨에 추가해보겠습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /fsxz/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

이제 두 번째 UI Pod가 새로 생성된 이 파일에 액세스할 수 있는지 확인하여 FSx for OpenZFS 스토리지의 공유 특성을 입증하겠습니다:

```bash
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /fsxz/'
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

보시다시피 첫 번째 Pod를 통해 파일을 생성했지만 두 번째 Pod도 즉시 액세스할 수 있습니다. 이는 두 Pod가 모두 동일한 공유 FSx for OpenZFS 파일 시스템에 액세스하고 있기 때문입니다.

마지막으로 UI 서비스를 통해 이미지에 액세스할 수 있는지 확인해보겠습니다:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

브라우저에서 URL을 방문하세요:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/fsx-for-openzfs/placeholder.jpg').default}/>
</Browser>

Amazon FSx for OpenZFS가 Amazon EKS에서 실행되는 워크로드에 영구 공유 스토리지를 제공하는 방법을 성공적으로 시연했습니다. 이 솔루션을 사용하면 여러 Pod가 동일한 스토리지 볼륨에서 동시에 읽고 쓸 수 있어 공유 콘텐츠 호스팅 및 고성능과 엔터프라이즈 기능을 갖춘 분산 파일 시스템 액세스가 필요한 기타 사용 사례에 이상적입니다.

