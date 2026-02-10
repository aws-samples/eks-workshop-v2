---
title: "コスト配分"
sidebar_position: 20
tmdTranslationSourceHash: da8a1b55bbd61a86d95fa2ea810b3e43
---

次に、コスト配分を見てみましょう。<b>Cost Allocation</b>をクリックしてください。

以下のようなダッシュボードが表示されるはずです：

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation.webp').default}/>
</Browser>

このスクリーンを使用して、クラスターのコスト配分をさらに詳しく調査できます。様々なコスト次元を見ることができます：

- namespace（名前空間）
- deployment（デプロイメント）
- pod
- labels（ラベル）

はじめに紹介したセクションでインストールしたアプリケーションは、これらのコンポーネントをいくつか作成しました。次に、これらの次元を使用してこのアプリケーションのコストを詳しく見てみましょう。

これを行うには、右上の<b>Aggregate by</b>の横にある設定ボタンをクリックします。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation-filter.webp').default}/>
</Browser>

次に、<b>Filters</b>の下でドロップダウンメニューから<b>label</b>を選択し、値として`app.kubernetes.io/created-by: eks-workshop`を入力し、プラス記号をクリックします。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation-label.webp').default}/>
</Browser>

これにより、名前空間がフィルタリングされ、ラベル`app.kubernetes.io/create-by: eks-workshop`を持つワークロードのみが表示されます。このラベルは、はじめに紹介したセクションで起動したアプリケーションのすべてのコンポーネントに含まれています。

次に<b>Aggregate by</b>をクリックし、<b>Deployment</b>を選択します。これにより、名前空間ではなくデプロイメントごとにコストが集計されます。以下を参照してください。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/aggregate-by-deployment.webp').default}/>
</Browser>

アプリケーションに関連する異なるデプロイメントがあることがわかります。さらに詳しく調査できます。単一の名前空間を見てみましょう。<b>Aggregate by</b>を<b>Namespace</b>に戻し、フィルターを削除して、テーブル内の名前空間の1つをクリックします。ここではorders名前空間を選択しました。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/namespace.webp').default}/>
</Browser>

このビューでは、この名前空間で実行されているKubernetesリソースに関連するすべてのコストを確認できます。これは、マルチテナントクラスターを持ち、顧客ごとに名前空間がある場合に役立つビューとなります。

また、この名前空間で実行されているさまざまなリソースとそれらに関連するコストを確認することもできます。

![Orders Namespace Resources](/docs/observability/kubecost/orders.webp)

<b>Controllers</b>の下のエントリの1つをクリックします。ここではordersデプロイメントをクリックしました。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/controllers.webp').default}/>
</Browser>

このビューでは、特定の「コントローラー」（この場合はデプロイメント）の詳細が表示されます。この情報を使用して、どのような最適化が可能かを理解し始めることができます。例えば、リソース要求と制限を調整して、EKSクラスター内の各ポッドに割り当てられるCPUとメモリの量を制限するなどです。

これまで、コスト配分の広範な概要または単一リソースの詳細な調査を見てきました。チームごとにコスト配分を深く掘り下げたい場合はどうすればよいでしょうか？以下のシナリオを考えてみましょう：会社の各チームがクラスター内の運用コストに責任を持っています。例えば、クラスター内のすべてのデータベースに責任を持つチームがあり、彼らは運用コストを詳しく調べたいと考えています。これは、各データベースにそのチームに関連するカスタムラベルを付けることで実現できます。私たちのクラスターでは、すべてのデータベースリソースにラベル`app.kubernetes.io/team: database`を付けています。このラベルを使用して、このチームに属する異なる名前空間にまたがるすべてのリソースをフィルタリングできます。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/team.webp').default}/>
</Browser>

Kubecostには、Savings、Health、Reports、Alertsなど他にも多くの機能があります。さまざまなリンクを自由に試してみてください。

