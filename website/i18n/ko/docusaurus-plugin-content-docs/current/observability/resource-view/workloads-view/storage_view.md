---
title: "스토리지"
sidebar_position: 40
tmdTranslationSourceHash: '93d12c43499d46c34c149ebaf65d1917'
---

Kubernetes 스토리지 리소스를 보려면 <i>Resources</i> 탭을 클릭하세요. <i>Storage</i> 섹션으로 드릴다운하면 클러스터의 일부인 스토리지와 관련된 여러 Kubernetes API 리소스 유형을 볼 수 있습니다:

- Persistent Volume Claims
- Persistent Volumes
- Storage Classes
- Volume Attachments
- CSI Drivers
- CSI Nodes

[Storage](../../../fundamentals/storage/) 워크샵 모듈에서는 상태 저장 워크로드를 위한 스토리지를 구성하고 사용하는 방법에 대해 더 자세히 설명합니다.

[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC)은 사용자의 스토리지 요청입니다. 이 리소스는 Pod와 유사합니다. Pod는 노드 리소스를 소비하고 PVC는 Persistent Volume (PV) 리소스를 소비합니다. Pod는 특정 수준의 리소스(CPU 및 메모리)를 요청할 수 있습니다. Claim은 특정 크기와 액세스 모드를 요청할 수 있습니다(예: ReadWriteOnce, ReadOnlyMany 또는 ReadWriteMany로 마운트할 수 있습니다. 자세한 내용은 [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)를 참조하세요).

[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) PersistentVolume (PV)은 관리자가 프로비저닝하거나 [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)를 사용하여 동적으로 프로비저닝한 클러스터의 구성된 스토리지 단위입니다. 노드가 클러스터 리소스인 것처럼 클러스터의 리소스입니다. PV는 Volume과 같은 볼륨 플러그인이지만 PV를 사용하는 개별 Pod와 독립적인 라이프사이클을 가집니다. 이 API 객체는 EBS, EFS 또는 기타 타사 PV 공급자와 같은 스토리지 구현의 세부 정보를 캡처합니다.

[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)는 관리자가 클러스터에서 사용할 수 있는 스토리지 "클래스"를 설명하는 방법을 제공합니다. 서로 다른 클래스는 서비스 품질 수준, 백업 정책 또는 클러스터 관리자가 결정한 임의의 정책에 매핑될 수 있습니다.

[VolumeAttachment](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume-attachment-v1/)는 지정된 볼륨을 지정된 노드에 연결하거나 분리하려는 의도를 캡처합니다.

[Container Storage Interface (CSI)](https://kubernetes.io/docs/concepts/storage/volumes/#csi)는 Kubernetes가 컨테이너 워크로드에 임의의 스토리지 시스템을 노출할 수 있는 표준 인터페이스를 정의합니다.
Container Storage Interface (CSI) 노드 플러그인은 디스크 장치 스캔 및 파일 시스템 마운트와 같은 다양한 특권 작업을 수행하는 데 필요합니다. 이러한 작업은 각 호스트 운영 체제마다 다릅니다. Linux 워커 노드의 경우 컨테이너화된 CSI 노드 플러그인은 일반적으로 특권 컨테이너로 배포됩니다. Windows 워커 노드의 경우 컨테이너화된 CSI 노드 플러그인에 대한 특권 작업은 [csi-proxy](https://github.com/kubernetes-csi/csi-proxy)를 사용하여 지원되며, 이는 커뮤니티에서 관리하는 독립 실행형 바이너리로 각 Windows 노드에 사전 설치되어야 합니다.

