---
title: "コスト配分"
sidebar_position: 20
tmdTranslationSourceHash: '2aa93878eed433eb5a851cf8160564e9'
---

次に、コスト配分を見てみましょう。<b>Cost Allocation</b>をクリックしてください。

以下のようなダッシュボードが表示されるはずです。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation.webp').default}/>
</Browser>

この画面を使用して、クラスターのコスト配分をさらに詳しく調査できます。さまざまなコストの観点から確認できます。

- Namespace
- Deployment
- Pod
- ラベル

Introductionセクションでインストールしたアプリケーションは、これらのコンポーネントをいくつか作成しました。これらのコンポーネントにもそれぞれコストが発生しています。次に、これらの観点を使用してこのアプリケーションのコストを詳しく見ていきます。

これを行うには、右上の<b>Aggregate by</b>の横にある設定ボタンをクリックします。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation-filter.webp').default}/>
</Browser>

次に、<b>Filters</b>の下にあるドロップダウンメニューから<b>label</b>を選択し、値として`app.kubernetes.io/created-by: eks-workshop`を入力して、プラス記号をクリックします。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/costallocation-label.webp').default}/>
</Browser>

これにより、Namespaceが絞り込まれ、ラベル`app.kubernetes.io/created-by: eks-workshop`を持つワークロードのみが表示されます。このラベルは、Introductionセクションで起動したアプリケーションのすべてのコンポーネントに付与されています。

次に<b>Aggregate by</b>をクリックし、<b>Deployment</b>を選択します。これにより、Namespaceごとではなく、Deploymentごとにコストが集計されます。以下を参照してください。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/aggregate-by-deployment.webp').default}/>
</Browser>

アプリケーションに関連するさまざまなDeploymentがあることがわかります。さらに詳しく調べることができます。1つのNamespaceを見てみましょう。<b>Aggregate by</b>を<b>Namespace</b>に戻し、フィルターを削除して、テーブル内のNamespaceの1つをクリックします。ここではorders Namespaceを選択しました。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/namespace.webp').default}/>
</Browser>

このビューでは、このNamespaceで実行されているKubernetesリソースに関連するすべてのコストを確認できます。これは、マルチテナントクラスターで顧客ごとにNamespaceを割り当てている場合に役立つビューです。

また、このNamespaceで実行されているさまざまなリソースと、それらに関連するコストも確認できます。

![Orders Namespaceのリソース](/docs/observability/kubecost/orders.webp)

<b>Controllers</b>の下にあるエントリの1つをクリックします。ここではorders Deploymentをクリックしました。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/controllers.webp').default}/>
</Browser>

このビューでは、特定の「コントローラー」（この場合はDeployment）の詳細が表示されます。この情報を使用して、どのような最適化ができるかを検討し始めることができます。たとえば、リソースのリクエストと制限を調整して、EKSクラスター内の各Podに割り当てられるCPUとメモリの量を抑えるといった最適化です。

ここまでは、コスト配分の大まかな概要、または単一リソースの詳細な調査を見てきました。では、チームごとにコスト配分を掘り下げたい場合はどうすればよいでしょうか。次のようなシナリオを考えてみましょう。会社の各チームが、クラスター内での運用コストに責任を持っているとします。たとえば、クラスター内のすべてのデータベースを担当するチームがあり、そのチームが自分たちの運用コストを詳しく調べたいと考えています。これは、各データベースにそのチームに関連するカスタムラベルを付与することで実現できます。このクラスターでは、すべてのデータベースリソースにラベル`app.kubernetes.io/team: database`を付与しています。このラベルを使用して、複数のNamespaceにまたがる、このチームに属するすべてのリソースをフィルタリングできます。

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090/allocations'>
<img src={require('@site/static/docs/observability/kubecost/team.webp').default}/>
</Browser>

Kubecostには、Savings、Health、Reports、Alertsなど、他にも多くの機能があります。さまざまなリンクを自由に試してみてください。
