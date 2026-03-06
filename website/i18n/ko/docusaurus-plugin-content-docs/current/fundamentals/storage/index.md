---
title: Storage
sidebar_position: 20
tmdTranslationSourceHash: '7c5e65e15040162b68a4e81ed20e58ba'
---

[EKS의 스토리지](https://docs.aws.amazon.com/eks/latest/userguide/storage.html)는 두 가지 AWS 스토리지 서비스를 EKS 클러스터와 통합하는 방법에 대한 개괄적인 개요를 제공합니다.

구현에 들어가기 전에, EKS와 통합하여 사용할 두 가지 AWS 스토리지 서비스에 대한 요약은 다음과 같습니다:

- [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (EC2만 지원): EC2 인스턴스와 컨테이너에서 전용 스토리지 볼륨으로의 직접 액세스를 제공하는 블록 스토리지 서비스로, 모든 규모에서 처리량 및 트랜잭션 집약적인 워크로드 모두를 위해 설계되었습니다.
- [Amazon Elastic File System](https://aws.amazon.com/efs/) (Fargate 및 EC2 지원): 빅데이터 분석, 웹 서빙 및 콘텐츠 관리, 애플리케이션 개발 및 테스트, 미디어 및 엔터테인먼트 워크플로우, 데이터베이스 백업, 컨테이너 스토리지에 적합한 완전 관리형, 확장 가능하고 탄력적인 파일 시스템입니다. EFS는 데이터를 여러 가용 영역(AZ)에 중복으로 저장하고, 실행 중인 가용 영역에 관계없이 Kubernetes Pod에서 낮은 레이턴시 액세스를 제공합니다.
- [Amazon FSx for NetApp ONTAP](https://aws.amazon.com/fsx/netapp-ontap/) (EC2만 지원): NetApp의 인기 있는 ONTAP 파일 시스템을 기반으로 구축된 완전 관리형 공유 스토리지입니다. FSx for NetApp ONTAP은 데이터를 여러 가용 영역(AZ)에 중복으로 저장하고, 실행 중인 가용 영역에 관계없이 Kubernetes Pod에서 낮은 레이턴시 액세스를 제공합니다.
- [Amazon FSx for Lustre](https://aws.amazon.com/fsx/lustre/) (EC2만 지원): 머신 러닝, 고성능 컴퓨팅, 비디오 처리, 재무 모델링, 전자 설계 자동화 및 분석과 같은 워크로드에 최적화된 완전 관리형 고성능 스케일 아웃 파일 시스템입니다. FSx for Lustre를 사용하면 S3 데이터 리포지토리에 연결된 고성능 스케일 아웃 파일 시스템을 신속하게 생성하고 S3 객체에 파일로 투명하게 액세스할 수 있습니다.
- [Amazon FSx for OpenZFS](https://aws.amazon.com/fsx/openzfs/) (EC2만 지원): 자체 관리형 데이터베이스, 기간 업무 애플리케이션, 콘텐츠 관리 시스템, 패키지 관리자 및 기타 여러 워크로드와 같이 가장 낮은 레이턴시가 필요한 워크로드에 최적화된 완전 관리형 고성능 스케일 업 파일 시스템입니다. FSx for OpenZFS를 사용하면 모든 AWS 파일 서비스 중 가장 낮은 레이턴시와 GB당 가장 낮은 스토리지 가격으로 고가용성, 고성능 스케일 업 파일 시스템을 신속하게 생성할 수 있습니다.

또한 [Kubernetes 스토리지](https://kubernetes.io/docs/concepts/storage/)에 대한 몇 가지 개념에 익숙해지는 것이 매우 중요합니다:

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/): 컨테이너의 디스크 내 파일은 임시적이며, 이는 컨테이너에서 실행되는 중요한 애플리케이션에 몇 가지 문제를 제공합니다. 첫 번째 문제는 컨테이너가 충돌할 때 파일이 손실되는 것입니다. kubelet은 컨테이너를 재시작하지만 깨끗한 상태로 시작합니다. 두 번째 문제는 Pod에서 함께 실행되는 컨테이너 간에 파일을 공유할 때 발생합니다. Kubernetes 볼륨 추상화는 이 두 가지 문제를 모두 해결합니다. Pod에 대한 숙지가 권장됩니다.
- [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)는 이러한 사용 사례를 위해 설계되었습니다. 볼륨이 Pod의 수명 주기를 따르고 Pod와 함께 생성 및 삭제되기 때문에, Pod는 일부 영구 볼륨을 사용할 수 있는 위치에 제한받지 않고 중지 및 재시작될 수 있습니다.
- [Persistent Volumes (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)는 관리자가 프로비저닝했거나 Storage Classes를 사용하여 동적으로 프로비저닝한 클러스터의 스토리지 조각입니다. 이는 노드가 클러스터 리소스인 것처럼 클러스터의 리소스입니다. PV는 Volumes와 같은 볼륨 플러그인이지만 PV를 사용하는 개별 Pod와는 독립적인 수명 주기를 갖습니다. 이 API 객체는 NFS, iSCSI 또는 클라우드 제공업체별 스토리지 시스템 등 스토리지 구현의 세부 정보를 캡처합니다.
- [Persistent Volume Claim (PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)는 사용자의 스토리지 요청입니다. Pod와 유사합니다. Pod는 노드 리소스를 소비하고 PVC는 PV 리소스를 소비합니다. Pod는 특정 수준의 리소스(CPU 및 메모리)를 요청할 수 있습니다. 클레임은 특정 크기 및 액세스 모드를 요청할 수 있습니다(예: ReadWriteOnce, ReadOnlyMany 또는 ReadWriteMany로 마운트될 수 있으며, [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) 참조)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)는 관리자가 제공하는 스토리지의 "클래스"를 설명하는 방법을 제공합니다. 서로 다른 클래스는 서비스 품질 수준, 백업 정책 또는 클러스터 관리자가 결정한 임의의 정책에 매핑될 수 있습니다. Kubernetes 자체는 클래스가 무엇을 나타내는지에 대해 의견이 없습니다. 이 개념은 다른 스토리지 시스템에서 "프로필"이라고도 합니다.
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)을 사용하면 스토리지 볼륨을 온디맨드로 생성할 수 있습니다. 동적 프로비저닝이 없으면 클러스터 관리자는 클라우드 또는 스토리지 제공업체를 수동으로 호출하여 새 스토리지 볼륨을 생성한 다음 Kubernetes에서 이를 나타내는 PersistentVolume 객체를 생성해야 합니다. 동적 프로비저닝 기능은 클러스터 관리자가 스토리지를 미리 프로비저닝할 필요를 없앱니다. 대신 사용자가 요청할 때 자동으로 스토리지를 프로비저닝합니다.

다음 단계에서는 먼저 Kubernetes의 statefulset 객체를 사용하여 catalog 마이크로서비스의 MySQL 데이터베이스에서 소비될 Amazon EBS 볼륨을 통합할 것입니다.
그 후, component 마이크로서비스 파일 시스템을 Amazon EFS 공유 파일 시스템을 사용하도록 통합하여 마이크로서비스의 파일에 대한 확장성, 복원력 및 더 많은 제어를 제공할 것입니다.

