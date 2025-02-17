---
title: FSxN CSI 드라이버
sidebar_position: 20
---
이 섹션을 시작하기 전에, [스토리지](../index.md) 메인 섹션에서 소개된 Kubernetes 스토리지 객체(볼륨, 영구 볼륨(PV), 영구 볼륨 클레임(PVC), 동적 프로비저닝 및 임시 스토리지)에 대해 숙지하시기 바랍니다.

[Amazon FSx for NetApp ONTAP Container Storage Interface(CSI) 드라이버](https://github.com/NetApp/trident)는 상태 저장 컨테이너화된 애플리케이션을 실행하는 데 도움을 줍니다. Amazon FSx for NetApp ONTAP 컨테이너 스토리지 인터페이스(CSI) 드라이버는 AWS에서 실행되는 Kubernetes 클러스터가 Amazon FSx for NetApp ONTAP 파일 시스템의 수명 주기를 관리할 수 있도록 CSI 인터페이스를 제공합니다.

EKS 클러스터에서 동적 프로비저닝으로 Amazon FSx for NetApp ONTAP 파일 시스템을 사용하기 위해서는 Amazon FSx for NetApp ONTAP CSI 드라이버가 설치되어 있는지 확인해야 합니다.[Amazon FSx for NetApp ONTAP Container Storage Interface(CSI) 드라이버](https://github.com/NetApp/trident)는 컨테이너 오케스트레이터가 Amazon FSx for NetApp ONTAP 파일 시스템의 수명 주기를 관리할 수 있도록 CSI 사양을 구현합니다.

워크샵 환경의 일부로 EKS 클러스터에는 Amazon FSx for NetApp ONTAP 컨테이너 스토리지 인터페이스(CSI) 드라이버가 사전 설치되어 있습니다. 다음과 같이 설치를 확인할 수 있습니다:

```bash
$ kubectl get pods -n trident
NAME                                  READY   STATUS    RESTARTS   AGE
trident-controller-68f86749df-tr9nw   6/6     Running   0          25m
trident-node-linux-7wkg9              2/2     Running   0          25m
trident-node-linux-9g6w4              2/2     Running   0          25m
trident-node-linux-vpvnh              2/2     Running   0          25m
trident-operator-56fb7f67c4-vws4m     1/1     Running   0          29m

```

FSx for NetApp ONTAP CSI 드라이버는 동적 및 정적 프로비저닝을 지원합니다. 현재 동적 프로비저닝은 각 영구 볼륨에 대한 액세스 포인트를 생성합니다. 이는 AWS EFS 파일 시스템을 먼저 AWS에서 수동으로 생성해야 하며 StorageClass 매개변수의 입력으로 제공해야 함을 의미합니다. 정적 프로비저닝의 경우, AWS EFS 파일 시스템을 먼저 AWS에서 수동으로 생성해야 합니다. 그 후 드라이버를 사용하여 볼륨으로 컨테이너 내부에 마운트할 수 있습니다.

워크샵 환경에는 FSx for NetApp ONTAP 파일 시스템, Storage Virtual Machine(SVM) 및 Pod에 대한 인바운드 NFS 트래픽을 허용하는 인바운드 규칙이 포함된 필요한 보안 그룹이 사전 프로비저닝되어 있습니다. 다음 AWS CLI 명령을 실행하여 FSx for NetApp ONTAP 파일 시스템에 대한 정보를 확인할 수 있습니다:

```bash
$ aws fsx describe-file-systems --file-system-id $FSXN_ID
```

이제 이 워크샵 인프라의 일부로 사전 프로비저닝된 FSx for NetApp ONTAP 파일 시스템을 사용하도록 구성된 TridentBackendConfig 객체를 생성해야 합니다.

Kustomize를 사용하여 백엔드를 생성하고 스토리지 클래스 객체의 구성에서 `managementLIF` 값에 환경 변수 `FSXN_IP`를 주입할 것입니다:

```file
manifests/modules/fundamentals/storage/fsxn/backend/fsxn-backend-nas.yaml
```

이 kustomization을 적용해보겠습니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/backend \
  | envsubst | kubectl apply -f-
secret/backend-fsxn-ontap-nas-secret created
tridentbackendconfig.trident.netapp.io/backend-fsxn-ontap-nas created
```

이제 아래 명령을 사용하여 TridentBackendConfig가 생성되었는지 확인해보겠습니다:

```bash
$ kubectl get tbc -n trident
NAME                     BACKEND NAME          BACKEND UUID                           PHASE   STATUS
backend-fsxn-ontap-nas   backend-fsxn-ontap-   61a731e0-2f3c-4df9-9e49-5fc120e8247c   Bound   Success
```

이제 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 생성해야 합니다.

스토리지 클래스를 생성하기 위해 Kustomize를 사용할 것입니다:

```file
manifests/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
```

이 kustomization을 적용해보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/storageclass/
storageclass.storage.k8s.io/fsxn-sc-nfs created
```

이제 아래 명령을 사용하여 StorageClass를 가져오고 설명해보겠습니다. 프로비저너로 `csi.trident.netapp.io`드라이버가 사용되고 프로비저닝 모드가 `ontap-nas`인 것을 확인하세요.

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxn-sc-nfs     csi.trident.netapp.io   Delete          Immediate              true                   44s

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

이제 EKS StorageClass와 FSxN CSI 드라이버에 대해 더 잘 이해했습니다. 다음 페이지에서는 Kubernetes 동적 볼륨 프로비저닝과 영구 볼륨을 사용하여 제품 이미지를 저장하기 위해 FSxN `StorageClass`를 활용하도록 `asset` 마이크로서비스를 수정하는 데 중점을 둘 것입니다.
