---
title: "Amazon VPC CNI"
sidebar_position: 3
chapter: true
weight: 20
tmdTranslationSourceHash: 'ba7a4eda2f22a760ef6a61b4def4fae1'
---

Pod 네트워킹은 클러스터 네트워킹이라고도 하며, Kubernetes 네트워킹의 중심입니다. Kubernetes는 클러스터 네트워킹을 위해 Container Network Interface (CNI) 플러그인을 지원합니다.

모듈 관리자 중 한 명인 Sheetal Joshi (AWS)의 네트워킹 모듈 비디오 안내를 여기에서 시청하세요:

<ReactPlayer controls src="https://www.youtube-nocookie.com/embed/EAZnXII9NTY" width={640} height={360} /> <br />

Amazon EKS는 Amazon VPC를 사용하여 워커 노드와 Kubernetes Pod에 네트워킹 기능을 제공합니다. EKS 클러스터는 두 개의 VPC로 구성됩니다: Kubernetes 컨트롤 플레인을 호스팅하는 AWS 관리형 VPC와 컨테이너가 실행되는 Kubernetes 워커 노드 및 클러스터에서 사용하는 기타 AWS 인프라(로드 밸런서 등)를 호스팅하는 두 번째 고객 관리형 VPC입니다. 모든 워커 노드는 관리형 API 서버 엔드포인트에 연결할 수 있는 기능이 필요합니다. 이 연결을 통해 워커 노드는 Kubernetes 컨트롤 플레인에 자신을 등록하고 애플리케이션 Pod를 실행하라는 요청을 받을 수 있습니다.

워커 노드는 EKS 퍼블릭 엔드포인트 또는 EKS 관리형 Elastic Network Interface (ENI)를 통해 EKS 컨트롤 플레인에 연결됩니다. 클러스터를 생성할 때 전달하는 서브넷은 EKS가 이러한 ENI를 배치하는 위치에 영향을 미칩니다. 최소 두 개의 가용 영역에 두 개 이상의 서브넷을 제공해야 합니다. 워커 노드가 연결하는 경로는 클러스터의 프라이빗 엔드포인트를 활성화했는지 여부에 따라 결정됩니다. EKS는 EKS 관리형 ENI를 사용하여 워커 노드와 통신합니다.

Amazon EKS는 Kubernetes Pod 네트워킹을 구현하기 위해 Amazon Virtual Private Cloud (VPC) CNI 플러그인을 공식적으로 지원합니다. VPC CNI는 AWS VPC와의 네이티브 통합을 제공하며 언더레이 모드에서 작동합니다. 언더레이 모드에서는 Pod와 호스트가 동일한 네트워크 계층에 위치하고 네트워크 네임스페이스를 공유합니다. Pod의 IP 주소는 클러스터와 VPC 관점에서 일관됩니다.

