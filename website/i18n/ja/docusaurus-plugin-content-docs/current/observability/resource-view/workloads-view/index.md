---
title: "リソース"
sidebar_position: 10
tmdTranslationSourceHash: a285d022a99b6f6a086ddc039767f22a
---

Kubernetesリソースを表示するには、<i>リソース</i>タブをクリックします。<i>ワークロード</i>セクションにドリルダウンすると、ワークロードの一部であるKubernetes APIリソースタイプをいくつか表示できます。ワークロードには、クラスター内で実行されているコンテナが含まれ、Pod、ReplicaSet、Deployment、DaemonSetなどが含まれます。これらはコンテナをクラスターで実行するための基本的な構成要素です。

<strong>[Pod](https://kubernetes.io/docs/concepts/workloads/pods/)</strong>リソースビューには、最小かつ最もシンプルなKubernetesオブジェクトであるすべてのポッドが表示されます。
デフォルトでは、すべてのKubernetes APIリソースタイプが表示されますが、名前空間でフィルタリングしたり、特定の値を検索したりして、必要なものをすばやく見つけることができます。以下では、namespace=<i>catalog</i>でフィルタリングされたポッドが表示されています。

![Insights](/img/resource-view/filter-pod.jpg)

すべてのKubernetes APIリソースタイプのリソースビューでは、構造化ビューと生のビューの2つのビューが提供されます。構造化ビューはリソースのデータにアクセスするのに役立つリソースの視覚的な表現を提供します。生のビューでは、Kubernetes APIからの完全なJSON出力が表示され、Amazon EKSコンソールで構造化ビューのサポートがないリソースタイプの構成と状態を理解するのに役立ちます。

![Insights](/img/resource-view/pod-detail-structured.jpg)

<strong>[ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)</strong>は、常に安定したレプリカポッドのセットが実行されることを保証するKubernetesオブジェクトです。そのため、指定された数の同一ポッドの可用性を保証するためによく使用されます。この例（以下）では、名前空間<i>orders</i>の2つのreplicasetを確認できます。orders-d6b4566fcのreplicasetは、希望するポッドの数と現在のポッドの数の構成を定義しています。

![Insights](/img/resource-view/replica-set.jpg)

replicaset <i>orders-d6b4566fc</i>をクリックして構成を確認してください。情報、ポッド、ラベルの構成と、最大レプリカ数と希望するレプリカ数の詳細が表示されます。

<strong>[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)</strong>は、ポッドとreplicaSetに宣言的な更新を提供するKubernetesオブジェクトです。Kubernetesにポッドのインスタンスを作成または変更する方法を指示します。Deploymentは、レプリカポッドの数をスケーリングし、デプロイメントバージョンを管理された方法でロールアウトまたはロールバックするのに役立ちます。この例（以下）では、名前空間<i>carts</i>の2つのデプロイメントを確認できます。

![Insights](/img/resource-view/deploymentSet.jpg)

デプロイメント<i>carts</i>をクリックして構成を確認してください。情報セクションにデプロイメント戦略、ポッドセクションにポッドの詳細、ラベルとデプロイメントリビジョンが表示されます。

<strong>[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)</strong>は、すべて（または一部の）ノードでポッドのコピーが実行されるようにします。サンプルアプリケーションでは、以下に示すように、各ノードで実行されているDaemonSetがあります。

![Insights](/img/resource-view/daemonset.jpg)

daemonset <i>kube-proxy</i>をクリックして構成を確認してください。情報セクション、各ノードで実行されているポッド、ラベル、アノテーションの構成が表示されます。
