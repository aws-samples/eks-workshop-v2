---
title: "컴퓨팅"
sidebar_position: 40
tmdTranslationSourceHash: '649b365d517f1c1b841e97b3b5967531'
---

[EKS의 컴퓨팅](https://docs.aws.amazon.com/eks/latest/userguide/eks-compute.html)은 컨테이너화된 워크로드를 실행하기 위한 여러 옵션을 제공하며, 각각 다른 사용 사례와 운영 요구 사항을 위해 설계되었습니다.

구현 내용을 살펴보기 전에, 우리가 탐색하고 EKS와 통합할 컴퓨팅 옵션에 대한 요약은 다음과 같습니다:

- [Amazon EKS Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html): EKS 클러스터를 위한 EC2 노드의 프로비저닝 및 수명 주기 관리를 자동화합니다. Managed Node Groups는 새로운 AMI 또는 Kubernetes 버전 배포를 위한 롤링 업데이트와 같은 운영 활동을 단순화하면서 기본 EC2 인스턴스에 대한 완전한 제어를 제공합니다.

- [Karpenter](https://karpenter.sh/): 애플리케이션 부하 변화에 대응하여 적절한 크기의 컴퓨팅 리소스를 자동으로 프로비저닝하는 오픈 소스 Kubernetes 클러스터 오토스케일러입니다. Karpenter는 필요에 따라 노드를 신속하게 시작하고 종료함으로써 애플리케이션 가용성과 클러스터 효율성을 개선합니다.


- [AWS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html): 가상 머신 그룹을 프로비저닝, 구성 또는 확장할 필요가 없는 컨테이너용 서버리스 컴퓨팅 엔진입니다. Fargate를 사용하면 인프라를 관리하는 대신 애플리케이션을 설계하고 구축하는 데 집중할 수 있습니다.


[Kubernetes 컴퓨팅 리소스](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)에 대한 주요 개념을 이해하는 것도 중요합니다:

- [Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/): 컨테이너화된 애플리케이션을 실행하는 Kubernetes의 워커 머신입니다. 각 노드에는 Pod를 실행하는 데 필요한 서비스가 포함되어 있으며 컨트롤 플레인에 의해 관리됩니다.
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/): Kubernetes에서 배포 가능한 가장 작은 단위로, 스토리지 및 네트워크 리소스를 공유하는 하나 이상의 컨테이너로 구성됩니다.
- [Resource Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/): 컨테이너가 필요로 하는 CPU 및 메모리 양(requests)과 사용할 수 있는 최대량(limits)을 지정하는 메커니즘입니다.
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity): 노드 레이블을 기반으로 Pod가 스케줄링될 수 있는 노드를 제한하는 규칙입니다.
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/): Pod가 부적절한 노드에 스케줄링되지 않도록 함께 작동하는 메커니즘입니다.

이 섹션에서 다루는 추가 컴퓨팅 고려 사항:

- **Graviton Processors**: EKS 워크로드에서 더 나은 가격 대비 성능을 위해 AWS Graviton 기반 EC2 인스턴스를 활용하는 방법을 알아봅니다.
- **Spot Instances**: 애플리케이션 가용성을 유지하면서 컴퓨팅 비용을 줄이기 위해 Amazon EC2 Spot Instances를 사용하는 방법을 이해합니다.
- **Cluster Autoscaler**: 기존 클러스터 오토스케일링 접근 방식을 살펴보고 Karpenter와 같은 최신 대안과 비교합니다.
- **Overprovisioning**: 클러스터에 여유 용량을 유지하여 Pod 스케줄링 대기 시간을 줄이는 전략을 구현합니다.

다음 실습에서는 EKS 컴퓨팅의 기본 사항을 이해하기 위해 Managed Node Groups부터 시작한 다음, 고급 오토스케일링 기능을 위한 Karpenter를 탐색하고, 마지막으로 서버리스 컨테이너 실행을 위한 Fargate를 살펴봅니다.

