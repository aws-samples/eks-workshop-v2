---
title: EFS CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: e381ce19d4fb30098d1dfe2c70ba6658
---

이 섹션을 시작하기 전에 메인 [스토리지](../index.md) 섹션에서 소개된 Kubernetes 스토리지 객체(볼륨, 영구 볼륨(PV), 영구 볼륨 클레임(PVC), 동적 프로비저닝 및 임시 스토리지)에 대해 숙지하고 있어야 합니다.

[Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)는 AWS에서 실행되는 Kubernetes 클러스터가 Amazon EFS 파일 시스템의 수명 주기를 관리할 수 있는 CSI 인터페이스를 제공하여 상태 유지 컨테이너화된 애플리케이션을 실행할 수 있게 합니다.

다음 아키텍처 다이어그램은 EKS Pod의 영구 스토리지로 EFS를 사용하는 방법을 보여줍니다:

![Assets with EFS](/docs/fundamentals/storage/efs/efs-storage.webp)

EKS 클러스터에서 동적 프로비저닝과 함께 Amazon EFS를 활용하려면 먼저 EFS CSI Driver가 설치되어 있는지 확인해야 합니다. 이 드라이버는 컨테이너 오케스트레이터가 전체 수명 주기 동안 Amazon EFS 파일 시스템을 관리할 수 있도록 하는 CSI 사양을 구현합니다.

보안 강화 및 관리 간소화를 위해 Amazon EFS CSI 드라이버를 Amazon EKS 애드온으로 실행할 수 있습니다. 필요한 IAM 역할이 이미 생성되어 있으므로 애드온 설치를 진행할 수 있습니다:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver \
  --service-account-role-arn $EFS_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
```

애드온이 EKS 클러스터에 생성한 내용을 살펴보겠습니다. 예를 들어, 클러스터의 각 노드에서 Pod를 실행하는 DaemonSet이 있습니다:

```bash
$ kubectl get daemonset efs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        47s
```

EFS CSI 드라이버는 동적 및 정적 프로비저닝을 모두 지원합니다:

- **동적 프로비저닝**: 드라이버는 각 PersistentVolume에 대해 액세스 포인트를 생성합니다. 이를 위해서는 StorageClass 파라미터에 지정되어야 하는 기존 AWS EFS 파일 시스템이 필요합니다.
- **정적 프로비저닝**: 이 역시 사전에 생성된 AWS EFS 파일 시스템이 필요하며, 이후 드라이버를 사용하여 컨테이너 내부에 볼륨으로 마운트할 수 있습니다.

EFS 파일 시스템이 마운트 대상 및 EFS 마운트 포인트에 대한 NFS 트래픽을 허용하는 인바운드 규칙이 포함된 필수 보안 그룹과 함께 프로비저닝되어 있습니다. 나중에 필요할 ID를 가져오겠습니다:

```bash
$ export EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='$EKS_CLUSTER_NAME-efs-assets'] | [0].FileSystemId" --output text)
$ echo $EFS_ID
fs-061cb5c5ed841a6b0
```

다음으로, 사전 프로비저닝된 EFS 파일 시스템과 프로비저닝 모드의 [EFS Access points](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html)를 사용하도록 구성된 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 `efsstorageclass.yaml` 파일을 사용하여 생성하겠습니다.

::yaml{file="manifests/modules/fundamentals/storage/efs/storageclass/efsstorageclass.yaml" paths="provisioner,parameters.fileSystemId"}

1. `provisioner` 파라미터를 EFS CSI 프로비저너를 위한 `efs.csi.aws.com`으로 설정합니다
2. `EFS_ID` 환경 변수를 `filesystemid` 파라미터에 주입합니다


kustomization을 적용합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/efs/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/efs-sc created
```

StorageClass를 살펴보겠습니다. EFS CSI 드라이버를 프로비저너로 사용하고 앞서 내보낸 파일 시스템 ID와 함께 EFS 액세스 포인트 프로비저닝 모드로 구성되어 있습니다:

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  8m29s
$ kubectl describe sc efs-sc
Name:            efs-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"efs-sc"},"parameters":{"directoryPerms":"700","fileSystemId":"fs-061cb5c5ed841a6b0","provisioningMode":"efs-ap"},"provisioner":"efs.csi.aws.com"}

Provisioner:           efs.csi.aws.com
Parameters:            directoryPerms=700,fileSystemId=fs-061cb5c5ed841a6b0,provisioningMode=efs-ap
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

이제 EFS StorageClass와 EFS CSI 드라이버의 작동 방식을 이해했으므로, UI 컴포넌트를 수정하여 Kubernetes 동적 볼륨 프로비저닝 및 제품 이미지 저장을 위한 PersistentVolume과 함께 EFS `StorageClass`를 사용하는 다음 단계로 진행할 준비가 되었습니다.

