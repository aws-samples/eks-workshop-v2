---
title: "클러스터"
sidebar_position: 10
tmdTranslationSourceHash: 'b8bf92d069a536552d0a94d548469cc8'
---

Kubernetes 클러스터 리소스를 보려면 <i>Resources</i> 탭을 클릭하세요. <i>Cluster</i> 섹션으로 드릴다운하면 클러스터의 일부인 여러 Kubernetes API 리소스 타입을 볼 수 있습니다. Cluster 뷰는 워크로드를 실행하는 Node, Namespace, API Service와 같은 클러스터 아키텍처의 모든 구성 요소를 자세히 보여줍니다.

Kubernetes는 컨테이너를 <strong>[Node](https://kubernetes.io/docs/concepts/architecture/nodes/)</strong>에서 실행되는 Pod에 배치하여 워크로드를 실행합니다. 노드는 클러스터에 따라 가상 또는 물리적 머신일 수 있습니다. eks-workshop은 워크로드가 배포된 3개의 노드에서 실행되고 있습니다. Nodes를 클릭하여 드릴다운하면 노드 목록이 표시됩니다.

![Insights](/img/resource-view/cluster-node.jpg)

노드 이름 중 하나를 클릭하면 Info 섹션에서 노드에 대한 많은 세부 정보를 찾을 수 있습니다 - OS, 컨테이너 런타임, 인스턴스 타입, EC2 인스턴스 및 [Managed node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) (클러스터의 컴퓨팅 용량을 쉽게 프로비저닝할 수 있게 해줍니다). 다음 섹션인 Capacity allocation은 클러스터에 연결된 EC2 워커 노드의 다양한 리소스 사용량과 예약량을 보여줍니다.

![Insights](/img/resource-view/cluster-node-detail1.jpg)
콘솔은 노드에 프로비저닝된 모든 Pod와 적용 가능한 [Taint](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/), 레이블 및 어노테이션도 자세히 표시합니다.

<strong>[Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces)</strong>는 클러스터를 구성하는 메커니즘으로, 서로 다른 팀이나 프로젝트가 Kubernetes 클러스터를 공유할 때 매우 유용할 수 있습니다. 샘플 애플리케이션에는 carts, checkout, catalog, assets와 같은 마이크로서비스가 있으며 모두 네임스페이스 구조를 사용하여 동일한 클러스터를 공유합니다.

![Insights](/img/resource-view/cluster-ns.jpg)

