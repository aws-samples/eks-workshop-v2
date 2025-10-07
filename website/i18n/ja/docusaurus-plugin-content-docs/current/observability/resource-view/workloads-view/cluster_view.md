---
title: "クラスター"
sidebar_position: 10
kiteTranslationSourceHash: b8bf92d069a536552d0a94d548469cc8
---

Kubernetesクラスターリソースを表示するには、<i>リソース</i>タブをクリックしてください。<i>クラスター</i>セクションを展開すると、クラスターの一部である複数のKubernetes APIリソースタイプを表示できます。クラスタービューでは、ワークロードを実行するノード、名前空間、APIサービスなどのクラスターアーキテクチャのすべてのコンポーネントの詳細が表示されます。

Kubernetesは、コンテナをポッドに配置することでワークロードを実行し、<strong>[ノード](https://kubernetes.io/docs/concepts/architecture/nodes/)</strong>上で実行します。クラスターによって、ノードは仮想マシンまたは物理マシンである場合があります。eks-workshopでは、ワークロードがデプロイされている3つのノードが実行されています。ノードドリルダウンをクリックしてノードのリストを表示します。

![インサイト](/img/resource-view/cluster-node.jpg)

いずれかのノード名をクリックすると、OS、コンテナランタイム、インスタンスタイプ、EC2インスタンス、および[マネージドノードグループ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)（クラスターのコンピューティングキャパシティを簡単にプロビジョニングできるようにします）など、ノードの詳細情報が表示されます。次のセクションであるキャパシティ配分では、クラスターに接続されたEC2ワーカーノード上の様々なリソースの使用状況と予約状況が表示されます。

![インサイト](/img/resource-view/cluster-node-detail1.jpg)
コンソールには、ノードにプロビジョニングされたすべてのポッドと、適用可能な[テイント](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)、ラベル、注釈も表示されます。

<strong>[名前空間](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces)</strong>は、異なるチームやプロジェクトがKubernetesクラスターを共有する場合に非常に役立つクラスターを整理するためのメカニズムです。サンプルアプリケーションでは、carts、checkout、catalog、assetsなどのマイクロサービスがすべて名前空間構造を使用して同じクラスターを共有しています。

![インサイト](/img/resource-view/cluster-ns.jpg)

