---
title: "리소스"
sidebar_position: 10
tmdTranslationSourceHash: 'a285d022a99b6f6a086ddc039767f22a'
---

Kubernetes 리소스를 보려면 <i>Resources</i> 탭을 클릭하세요. <i>Workload</i> 섹션으로 드릴다운하면 워크로드의 일부인 여러 Kubernetes API 리소스 타입을 볼 수 있습니다. 워크로드는 클러스터에서 실행 중인 컨테이너를 포함하며, Pod, ReplicaSet, Deployment, DaemonSet을 포함합니다. 이들은 클러스터 내에서 컨테이너를 실행하기 위한 기본 구성 요소입니다.

<strong>[Pod](https://kubernetes.io/docs/concepts/workloads/pods/)</strong> 리소스 뷰는 가장 작고 단순한 Kubernetes 객체를 나타내는 모든 pod를 표시합니다.
기본적으로 모든 Kubernetes API 리소스 타입이 표시되지만, 네임스페이스로 필터링하거나 특정 값을 검색하여 원하는 것을 빠르게 찾을 수 있습니다. 아래에서는 namespace=<i>catalog</i>로 필터링된 pod를 볼 수 있습니다.

![Insights](/img/resource-view/filter-pod.jpg)

모든 Kubernetes API 리소스 타입의 리소스 뷰는 구조화된 뷰와 원시 뷰 두 가지 뷰를 제공합니다. 구조화된 뷰는 리소스의 데이터에 액세스하는 데 도움이 되는 리소스의 시각적 표현을 제공합니다. 원시 뷰는 Kubernetes API의 전체 JSON 출력을 보여주며, Amazon EKS 콘솔에서 구조화된 뷰를 지원하지 않는 리소스 타입의 구성 및 상태를 이해하는 데 유용합니다.

![Insights](/img/resource-view/pod-detail-structured.jpg)

<strong>[ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)</strong>은 안정적인 replica pod 세트가 항상 실행되도록 보장하는 Kubernetes 객체입니다. 따라서 지정된 수의 동일한 pod의 가용성을 보장하는 데 자주 사용됩니다. 이 예제(아래)에서는 namespace <i>orders</i>에 대한 2개의 replicaset을 볼 수 있습니다. orders-d6b4566fc replicaset은 원하는 pod 수와 현재 pod 수에 대한 구성을 정의합니다.

![Insights](/img/resource-view/replica-set.jpg)

replicaset <i>orders-d6b4566fc</i>를 클릭하고 구성을 살펴보세요. Info, Pod, 레이블 및 최대 및 원하는 replica에 대한 세부 정보 아래에서 구성을 볼 수 있습니다.

<strong>[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)</strong>는 Pod와 ReplicaSet에 선언적 업데이트를 제공하는 Kubernetes 객체입니다. Kubernetes에 pod의 인스턴스를 생성하거나 수정하는 방법을 알려줍니다. Deployment는 replica pod의 수를 확장하고 제어된 방식으로 배포 버전을 롤아웃하거나 롤백하는 데 도움이 됩니다. 이 예제(아래)에서는 namespace <i>carts</i>에 대한 2개의 deployment를 볼 수 있습니다.

![Insights](/img/resource-view/deploymentSet.jpg)

deployment <i>carts</i>를 클릭하고 구성을 살펴보세요. Info 아래의 배포 전략, Pod 아래의 pod 세부 정보, 레이블 및 배포 리비전을 볼 수 있습니다.

<strong>[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)</strong>은 모든 (또는 일부) 노드가 pod의 복사본을 실행하도록 보장합니다. 샘플 애플리케이션에는 아래와 같이 각 노드에서 실행되는 DaemonSet이 있습니다.

![Insights](/img/resource-view/daemonset.jpg)

daemonset <i>kube-proxy</i>를 클릭하고 구성을 살펴보세요. Info 아래의 구성, 각 노드에서 실행되는 pod, 레이블 및 어노테이션을 볼 수 있습니다.

