---
title: FSx for NetApp ONTAP CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: 15cdbda44d1d25a0e88fb88a737efc18
---

이 섹션을 시작하기 전에, 주요 [Storage](../index.md) 섹션에서 소개된 Kubernetes 스토리지 객체(볼륨, Persistent Volume (PV), Persistent Volume Claim (PVC), 동적 프로비저닝 및 임시 스토리지)에 익숙해져야 합니다.

[Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) Driver](https://github.com/NetApp/trident)는 AWS에서 실행되는 Kubernetes 클러스터가 Amazon FSx for NetApp ONTAP 파일 시스템의 라이프사이클을 관리할 수 있도록 CSI 인터페이스를 제공하여 상태 저장 컨테이너화된 애플리케이션을 실행할 수 있게 합니다.

다음 아키텍처 다이어그램은 EKS Pod에 대한 영구 스토리지로 FSx for NetApp ONTAP를 사용하는 방법을 보여줍니다:

![Assets with FSx for NetApp ONTAP](/docs/fundamentals/storage/fsx-for-netapp-ontap/fsxn-storage.webp)

EKS 클러스터에서 동적 프로비저닝과 함께 Amazon FSx for NetApp ONTAP를 활용하려면, 먼저 FSx for NetApp ONTAP CSI Driver가 설치되어 있는지 확인해야 합니다. 이 드라이버는 컨테이너 오케스트레이터가 Amazon FSx for NetApp ONTAP 파일 시스템의 전체 라이프사이클을 관리할 수 있도록 하는 CSI 사양을 구현합니다.

helm을 사용하여 Amazon FSxN for NetApp ONTAP Trident CSI 드라이버를 설치할 수 있습니다. 워크샵 준비 과정에서 이미 생성된 필수 IAM 역할을 제공해야 합니다.

```bash wait=60
$ helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
$ helm install trident-operator netapp-trident/trident-operator \
  --version 100.2410.0 --namespace trident --create-namespace --wait
```

다음과 같이 설치를 확인할 수 있습니다:

```bash
$ kubectl get pods -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-controller-b6b5899-kqdjh    6/6     Running   0          87s
trident-node-linux-9q4sj            2/2     Running   0          86s
trident-node-linux-bxg5s            2/2     Running   0          86s
trident-node-linux-z92x2            2/2     Running   0          86s
trident-operator-588c7c854d-t4c4x   1/1     Running   0          102s
```

FSx for NetApp ONTAP 파일 시스템이 Storage Virtual Machine (SVM) 및 FSx 마운트 포인트에 대한 NFS 트래픽을 허용하는 인바운드 규칙을 포함하는 필수 보안 그룹과 함께 프로비저닝되었습니다. 나중에 필요할 ID를 가져오겠습니다:

```bash
$ export FSXN_ID=$(aws fsx describe-file-systems --output json | jq -r --arg cluster_name "${EKS_CLUSTER_NAME}-fsxn" '.FileSystems[] | select(.Tags[] | select(.Key=="Name" and .Value==$cluster_name)) | .FileSystemId')
$ echo $FSXN_ID
fs-0123456789abcdef0
```

FSx for NetApp ONTAP CSI 드라이버는 동적 및 정적 프로비저닝을 모두 지원합니다:

- **동적 프로비저닝**: 드라이버가 기존 FSx for NetApp ONTAP 파일 시스템에 볼륨을 생성합니다. 이를 위해서는 StorageClass 매개변수에 지정해야 하는 기존 AWS FSx for NetApp ONTAP 파일 시스템이 필요합니다.
- **정적 프로비저닝**: 이것도 사전 생성된 AWS FSx for NetApp ONTAP 파일 시스템이 필요하며, 이는 드라이버를 사용하여 컨테이너 내부의 볼륨으로 마운트될 수 있습니다.

다음으로, 사전 프로비저닝된 FSx for NetApp ONTAP 파일 시스템을 사용하도록 구성된 TridentBackendConfig 객체를 생성하겠습니다. 이를 위해 백엔드를 생성하는 데 사용할 `fsxn-backend-nas.yaml` 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/fsxn/backend/fsxn-backend-nas.yaml" paths="spec.svm,spec.aws.fsxFilesystemID,spec.credentials.name"}

1. `svm` 매개변수에 `EKS_CLUSTER_NAME` 환경 변수 주입 - 이것은 Storage Virtual Machine 이름입니다
2. `fsxFilesystemID` 매개변수에 `FSXN_ID` 환경 변수 주입 - 이것은 CSI 드라이버를 연결할 FSxN 파일 시스템입니다
3. `credentials.name` 매개변수에 `FSXN_SECRET_ARN` 환경 변수 주입 - 이것은 ONTAP API 인터페이스에 연결하기 위한 자격 증명을 포함하는 AWS Secrets Manager에 안전하게 저장된 시크릿의 ARN입니다

백엔드 구성을 적용합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/backend \
  | envsubst | kubectl apply -f-
tridentbackendconfig.trident.netapp.io/backend-tbc-ontap-nas created
```

TridentBackendConfig가 생성되었는지 확인합니다:

```bash
$ kubectl get tbc -n trident
NAME                    BACKEND NAME    BACKEND UUID                           PHASE   STATUS
backend-tbc-ontap-nas   tbc-ontap-nas   bbae8686-25e4-4fca-a4c7-7ab664c7db9c   Bound   Success
```

이제 `fsxnstorageclass.yaml` 파일을 사용하여 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 생성하겠습니다:

::yaml{file="manifests/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml" paths="provisioner,parameters.backendType"}

1. `provisioner` 매개변수를 Amazon FSx for NetApp ONTAP CSI 프로비저너를 위해 `csi.trident.netapp.io`로 설정합니다
2. `backendType`을 `ontap-nas`로 설정하여 ONTAP 볼륨에 액세스하기 위해 ONTAP NAS 드라이버를 사용해야 함을 나타냅니다

StorageClass를 적용합니다:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
storageclass.storage.k8s.io/fsxn-sc-nfs created
```

StorageClass를 살펴보겠습니다. 프로비저너로 FSx for NetApp ONTAP CSI 드라이버를 사용하고 ONTAP NAS 프로비저닝 모드로 구성되어 있음을 확인하세요:

```bash
$ kubectl get storageclass
NAME            PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxn-sc-nfs     csi.trident.netapp.io      Delete          Immediate              true                   8m29s
$ kubectl describe sc fsxn-sc-nfs
Name:            fsxn-sc-nfs
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxn-sc-nfs"},"parameters":{"backendType":"ontap-nas"},"provisioner":"csi.trident.netapp.io"}

Provisioner:           csi.trident.netapp.io
Parameters:            backendType=ontap-nas
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

이제 FSx for NetApp ONTAP StorageClass와 FSx for NetApp ONTAP CSI 드라이버의 작동 방식을 이해했으므로, UI 컴포넌트를 수정하여 Kubernetes 동적 볼륨 프로비저닝과 제품 이미지 저장을 위한 PersistentVolume과 함께 FSx for NetApp ONTAP `StorageClass`를 사용하는 다음 단계로 진행할 준비가 되었습니다.

