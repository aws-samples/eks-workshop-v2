---
title: EFS를 사용한 동적 프로비저닝
sidebar_position: 30
tmdTranslationSourceHash: 3ebb6d789f8ef01214bb12b1eca28f1e
---

이제 Kubernetes용 EFS 스토리지 클래스를 이해했으니, [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 생성하고 UI 컴포넌트가 이 볼륨을 마운트하도록 수정해보겠습니다.

먼저 `efspvclaim.yaml` 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/efs/deployment/efspvclaim.yaml" paths="kind,spec.storageClassName,spec.resources.requests.storage"}

1. 정의되는 리소스는 PersistentVolumeClaim입니다
2. 이는 앞서 생성한 `efs-sc` 스토리지 클래스를 참조합니다
3. 5GB의 스토리지를 요청하고 있습니다

이제 UI 컴포넌트가 EFS PVC를 참조하도록 업데이트하겠습니다:

```kustomization
modules/fundamentals/storage/efs/deployment/deployment.yaml
Deployment/ui
```

다음 명령으로 이러한 변경 사항을 적용합니다:

```bash hook=efs-deployment
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/efs/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolumeclaim/efs-claim created
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

배포의 `volumeMounts`를 살펴보겠습니다. `efsvolume`이라는 이름의 새 볼륨이 `/efs`에 마운트된 것을 확인할 수 있습니다:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /efs
  name: efsvolume
- mountPath: /tmp
  name: tmp-volume
```

PersistentVolume (PV)이 우리의 PersistentVolumeClaim (PVC)을 충족하기 위해 자동으로 생성되었습니다:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    ui/efs-claim                      efs-sc                  2m33s
```

PersistentVolumeClaim (PVC)의 세부 정보를 살펴보겠습니다:

```bash
$ kubectl describe pvc -n ui
Name:          efs-claim
Namespace:     ui
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
  Normal  Provisioning           34s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  External provisioner is provisioning volume for claim "ui/efs-claim"
  Normal  ProvisioningSucceeded  33s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

이 시점에서 EFS 파일 시스템이 성공적으로 마운트되었지만 현재 비어 있습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /efs/'
```

[Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)을 사용하여 EFS 볼륨에 이미지를 채워보겠습니다:

```bash
$ export PVC_NAME="efs-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

이제 UI 컴포넌트 Pod 중 하나를 통해 `/efs`의 현재 파일을 나열하여 공유 스토리지 기능을 시연해보겠습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /efs/'
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

공유 스토리지 기능을 더욱 시연하기 위해 `placeholder.jpg`라는 새 이미지를 생성하고 첫 번째 Pod를 통해 EFS 볼륨에 추가해보겠습니다:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /efs/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

이제 두 번째 UI Pod가 새로 생성된 이 파일에 접근할 수 있는지 확인하여 EFS 스토리지의 공유 특성을 시연하겠습니다:

```bash hook=sample-images
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /efs/'
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

보시다시피 첫 번째 Pod를 통해 파일을 생성했지만, 두 번째 Pod도 동일한 공유 EFS 파일 시스템에 접근하고 있기 때문에 즉시 파일에 접근할 수 있습니다.

마지막으로 UI 서비스를 통해 이미지에 접근할 수 있는지 확인해보겠습니다:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

브라우저에서 URL을 방문하세요:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/efs/placeholder.jpg').default}/>
</Browser>

Amazon EFS가 Amazon EKS에서 실행되는 워크로드에 영구 공유 스토리지를 제공하는 방법을 성공적으로 시연했습니다. 이 솔루션을 통해 여러 Pod가 동시에 동일한 스토리지 볼륨에서 읽고 쓸 수 있어 공유 콘텐츠 호스팅 및 분산 파일 시스템 액세스가 필요한 기타 사용 사례에 이상적입니다.

