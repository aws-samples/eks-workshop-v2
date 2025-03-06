---
title: "클러스터"
sidebar_position: 10
---

Kubernetes 클러스터 리소스를 보려면 <i>리소스</i> 탭을 클릭하세요. <i>클러스터</i> 섹션으로 드릴다운하면 클러스터의 일부인 여러 Kubernetes API 리소스 유형을 볼 수 있습니다. 클러스터 뷰는 워크로드를 실행하는 노드, 네임스페이스, API 서비스와 같은 클러스터 아키텍처의 모든 구성 요소를 자세히 보여줍니다.

Kubernetes는 컨테이너를 파드에 배치하여 <strong>[노드](https://kubernetes.io/docs/concepts/architecture/nodes/)</strong>에서 실행함으로써 워크로드를 실행합니다. 노드는 클러스터에 따라 가상 머신이나 물리적 머신일 수 있습니다. eks-workshop은 워크로드가 배포되는 3개의 노드에서 실행됩니다. 노드 드릴다운을 클릭하여 노드 목록을 확인하세요.

![인사이트](/img/resource-view/cluster-node.jpg)

노드 이름 중 하나를 클릭하면 노드에 대한 많은 세부 정보가 포함된 정보 섹션을 찾을 수 있습니다 - OS, 컨테이너 런타임, 인스턴스 유형, EC2 인스턴스 및 [관리형 노드 그룹](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) (클러스터의 컴퓨팅 용량을 쉽게 프로비저닝할 수 있게 해줍니다). 다음 섹션인 용량 할당은 클러스터에 연결된 EC2 작업자 노드의 다양한 리소스 사용량과 예약을 보여줍니다.

![인사이트](/img/resource-view/cluster-node-detail1.jpg)
콘솔은 또한 노드에 프로비저닝된 모든 파드와 적용 가능한 [테인트](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/), 레이블, 주석을 자세히 보여줍니다.

<strong>[네임스페이스](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces)</strong>는 클러스터를 구성하는 메커니즘으로, 서로 다른 팀이나 프로젝트가 Kubernetes 클러스터를 공유할 때 매우 유용할 수 있습니다. 우리의 샘플 애플리케이션에서는 carts, checkout, catalog, assets와 같은 마이크로서비스들이 네임스페이스 구성을 사용하여 동일한 클러스터를 공유합니다.

![인사이트](/img/resource-view/cluster-ns.jpg)