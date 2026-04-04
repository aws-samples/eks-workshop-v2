---
title: FSx for OpenZFS CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: 42b5d289881ac60bdd73a62ac3e2f2d4
---

이 섹션을 시작하기 전에 주요 [스토리지](../index.md) 섹션에서 소개된 Kubernetes 스토리지 객체(볼륨, 퍼시스턴트 볼륨(PV), 퍼시스턴트 볼륨 클레임(PVC), 동적 프로비저닝 및 임시 스토리지)에 익숙해져야 합니다.

[Amazon FSx for OpenZFS Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-fsx-openzfs-csi-driver)는 AWS에서 실행되는 Kubernetes 클러스터가 Amazon FSx for OpenZFS 파일 시스템 및 볼륨의 수명 주기를 관리할 수 있도록 CSI 인터페이스를 제공하여 상태 저장 컨테이너화된 애플리케이션을 실행할 수 있게 합니다.

다음 아키텍처 다이어그램은 FSx for OpenZFS를 EKS Pod의 퍼시스턴트 스토리지로 사용하는 방법을 보여줍니다:

![Assets with FSx for OpenZFS](/docs/fundamentals/storage/fsx-for-openzfs/fsxz-storage.webp)

EKS 클러스터에서 동적 프로비저닝을 통해 Amazon FSx for OpenZFS를 활용하려면 먼저 FSx for OpenZFS CSI Driver가 설치되어 있는지 확인해야 합니다. 이 드라이버는 컨테이너 오케스트레이터가 Amazon FSx for OpenZFS 파일 시스템 및 볼륨을 전체 수명 주기 동안 관리할 수 있도록 하는 CSI 사양을 구현합니다.

실습 준비의 일환으로 CSI 드라이버가 적절한 AWS API를 호출할 수 있도록 IAM 역할이 이미 생성되었습니다.

Helm을 사용하여 리포지토리를 추가하고 차트를 통해 FSx for OpenZFS CSI 드라이버를 설치합니다:

```bash timeout=300 wait=60
$ helm repo add aws-fsx-openzfs-csi-driver https://kubernetes-sigs.github.io/aws-fsx-openzfs-csi-driver
$ helm repo update
$ helm upgrade --install aws-fsx-openzfs-csi-driver \
    --namespace kube-system --wait \
    --set "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$FSXZ_IAM_ROLE" \
    aws-fsx-openzfs-csi-driver/aws-fsx-openzfs-csi-driver
```

차트가 EKS 클러스터에 생성한 것을 살펴보겠습니다. 예를 들어, 클러스터의 각 노드에서 Pod를 실행하는 DaemonSet이 있습니다:

```bash
$ kubectl get daemonset fsx-openzfs-csi-node -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
fsx-openzfs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        52s
```

FSx for OpenZFS CSI 드라이버는 동적 및 정적 프로비저닝을 모두 지원합니다. 동적 프로비저닝의 경우 드라이버는 FSx for OpenZFS 파일 시스템과 기존 파일 시스템에 볼륨을 모두 생성할 수 있습니다. 정적 프로비저닝을 사용하면 사전 생성된 FSx for OpenZFS 파일 시스템 또는 볼륨을 PersistentVolume(PV)과 연결하여 Kubernetes 내에서 사용할 수 있습니다. 드라이버는 또한 NFS 마운트 옵션 생성, 볼륨 스냅샷을 지원하며 볼륨 크기 조정을 허용합니다.

실습 준비의 일환으로 FSx for OpenZFS 파일 시스템이 이미 생성되었습니다. 이 실습에서는 FSx for OpenZFS 볼륨을 배포하도록 구성된 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 생성하여 동적 프로비저닝을 사용합니다.

FSx for OpenZFS 파일 시스템이 우리를 위해 프로비저닝되었으며, FSx 마운트 포인트에 대한 NFS 트래픽을 허용하는 인바운드 규칙을 포함하는 필요한 보안 그룹도 함께 생성되었습니다. 나중에 필요하므로 ID를 가져오겠습니다:

```bash
$ export FSXZ_FS_ID=$(aws fsx describe-file-systems --query "FileSystems[?Tags[?Key=='Name' && Value=='$EKS_CLUSTER_NAME-FSxZ']] | [0].FileSystemId" --output text)
$ echo $FSXZ_FS_ID
fs-0123456789abcdef0
```

FSx for OpenZFS CSI 드라이버는 동적 및 정적 프로비저닝을 모두 지원합니다:

- **동적 프로비저닝**: 드라이버는 FSx for OpenZFS 파일 시스템과 기존 파일 시스템에 볼륨을 모두 생성할 수 있습니다. 이를 위해서는 StorageClass 파라미터에 지정해야 하는 기존 AWS FSx for OpenZFS 파일 시스템이 필요합니다.
- **정적 프로비저닝**: 이 방법도 사전 생성된 AWS FSx for OpenZFS 파일 시스템 또는 볼륨이 필요하며, 드라이버를 사용하여 컨테이너 내부의 볼륨으로 마운트할 수 있습니다.

워크샵에서 FSx for OpenZFS 파일 시스템이 생성될 때 파일 시스템의 루트 볼륨도 함께 생성되었습니다. 루트 볼륨에 데이터를 저장하지 않고 대신 루트 아래에 별도의 하위 볼륨을 생성하여 데이터를 저장하는 것이 모범 사례입니다. 루트 볼륨은 워크샵에서 생성되었으므로 루트 볼륨 ID를 가져와서 파일 시스템 내에서 그 아래에 하위 볼륨을 생성할 수 있습니다.

다음을 실행하여 루트 볼륨 ID를 가져오고 Kustomize를 사용하여 볼륨 StorageClass에 주입할 환경 변수로 설정합니다:

```bash
$ export ROOT_VOL_ID=$(aws fsx describe-file-systems --file-system-id $FSXZ_FS_ID | jq -r '.FileSystems[] | .OpenZFSConfiguration.RootVolumeId')
$ echo $ROOT_VOL_ID
fsvol-0123456789abcdef0
```

다음으로, 사전 프로비저닝된 FSx for OpenZFS 파일 시스템을 사용하고 프로비저닝 모드에서 하위 볼륨을 생성하도록 구성된 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 생성합니다.

이를 위해 `fsxzstorageclass.yaml` 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/fsxz/storageclass/fsxzstorageclass.yaml" paths="provisioner,parameters.ParentVolumeId, parameters.NfsExports"}

1. FSx for OpenZFS CSI 프로비저너를 위해 `provisioner` 파라미터를 `fsx.openzfs.csi.aws.com`으로 설정합니다
2. `ROOT_VOL_ID` 환경 변수를 `ParentVolumeId` 파라미터에 할당합니다
3. `VPC_CIDR` 환경 변수를 `NfsExports` 파라미터에 주입합니다

kustomization을 적용합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxz/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/fsxz-vol-sc created
```

StorageClass를 살펴보겠습니다. 프로비저너로 FSx for OpenZFS CSI 드라이버를 사용하고 앞서 내보낸 루트 볼륨 ID로 볼륨 프로비저닝 모드로 구성되어 있습니다:

```bash
$ kubectl get storageclass
NAME            PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxz-vol-sc     fsx.openzfs.csi.aws.com    Delete          Immediate              false                  8m29s
$ kubectl describe sc fsxz-vol-sc
Name:            fsxz-vol-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":false,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxz-vol-sc"},"mountOptions":["nfsvers=4.1","rsize=1048576","wsize=1048576","timeo=600","nconnect=16"],"parameters":{"CopyTagsToSnapshots":"false","DataCompressionType":"\"LZ4\"","NfsExports":"[{\"ClientConfigurations\": [{\"Clients\": \"10.42.0.0/16\", \"Options\": [\"rw\",\"crossmnt\",\"no_root_squash\"]}]}]","OptionsOnDeletion":"[\"DELETE_CHILD_VOLUMES_AND_SNAPSHOTS\"]","ParentVolumeId":"\"fsvol-0efa720c2c77956a4\"","ReadOnly":"false","RecordSizeKiB":"128","ResourceType":"volume","Tags":"[{\"Key\": \"Name\", \"Value\": \"eks-workshop-data\"}]"},"provisioner":"fsx.openzfs.csi.aws.com","reclaimPolicy":"Delete"}

Provisioner:           fsx.openzfs.csi.aws.com
Parameters:            CopyTagsToSnapshots=false,DataCompressionType="LZ4",NfsExports=[{"ClientConfigurations": [{"Clients": "10.42.0.0/16", "Options": ["rw","crossmnt","no_root_squash"]}]}],OptionsOnDeletion=["DELETE_CHILD_VOLUMES_AND_SNAPSHOTS"],ParentVolumeId="fsvol-0efa720c2c77956a4",ReadOnly=false,RecordSizeKiB=128,ResourceType=volume,Tags=[{"Key": "Name", "Value": "eks-workshop-data"}]
AllowVolumeExpansion:  False
MountOptions:
  nfsvers=4.1
  rsize=1048576
  wsize=1048576
  timeo=600
  nconnect=16
ReclaimPolicy:      Delete
VolumeBindingMode:  Immediate
Events:             <none>
```

이제 FSx for OpenZFS StorageClass와 FSx for OpenZFS CSI 드라이버의 작동 방식을 이해했으므로, UI 컴포넌트를 수정하여 FSx for OpenZFS `StorageClass`를 Kubernetes 동적 볼륨 프로비저닝 및 PersistentVolume과 함께 사용하여 제품 이미지를 저장하는 다음 단계로 진행할 준비가 되었습니다.

