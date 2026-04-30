---
title: "Egressコントロールの実装"
sidebar_position: 70
tmdTranslationSourceHash: 'c3b515d0268ac59bde0627c5900ac0d1'
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

上記のアーキテクチャ図に示されているように、'ui'コンポーネントはフロントフェイシングアプリです。そこで、'ui'コンポーネントのネットワークコントロールの実装を開始するために、'ui'namespaceからのすべてのegressトラフィックをブロックするネットワークポリシーを定義します。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/default-deny.yaml" paths="spec.podSelector,spec.policyTypes"}

1. 空のセレクタ`{}`はすべてのPodにマッチします
2. `Egress`ポリシータイプはPodからのアウトバウンドトラフィックを制御します

> **注意** : ネットワークポリシーにはnamespaceが指定されていません。これは、クラスター内の任意のnamespaceに適用できる汎用ポリシーであるためです。

```bash wait=45
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

それでは、'ui'コンポーネントから'catalog'コンポーネントにアクセスしてみましょう。

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl http://catalog.catalog/health --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0
curl: (28) Resolving timed out after 5000 milliseconds
command terminated with exit code 28
```

curlコマンドの実行時に、以下の文が表示されるはずです。これは、'ui'コンポーネントが'catalog'コンポーネントと直接通信できなくなったことを示しています。

```text
curl: (28) Resolving timed out after 5000 milliseconds
```

上記のポリシーを実装すると、'ui'コンポーネントは'catalog'サービスやその他のサービスコンポーネントへのアクセスが必要であるため、サンプルアプリケーションが正しく機能しなくなります。'ui'コンポーネントに対して効果的なegressポリシーを定義するには、コンポーネントのネットワーク依存関係を理解する必要があります。

'ui'サービスが正常に機能するには、以下の3つのegressネットワーク接続が必要です。

1. 'catalog'、'orders'などの他のすべてのサービスと通信できる機能
2. `kube-system`などのクラスターシステムnamespace内のクラスター全体の共通ツールにアクセスできる機能
3. DNS名を解決するためにkube-dnsサービスにアクセスできる機能。EKS Auto Modeクラスターの場合、このIPは`172.20.0.10/32`です。以下の構成でこの接続が有効になります。

以下のネットワークポリシーは、上記の要件を念頭に置いて設計されています。

::yaml{file="manifests/modules/fastpaths/operators/network-policies/allow-ui-egress.yaml" paths="spec.egress.0.to.0,spec.egress.0.to.1,spec.egress.0.to.2"}

1. 最初のegressルールは、内部サービスのドメイン名解決のためにDNSサーバーへのegressトラフィックを許可することに焦点を当てています。
2. 最初のegressルールは、'catalog'、'orders'などのすべての`service`コンポーネントへのegressトラフィック（データベースコンポーネントへのアクセスは提供しない）を許可することに焦点を当てており、`namespaceSelector`と組み合わせることで、Podラベルが`app.kubernetes.io/component: service`と一致する限り、任意のnamespaceへのegressトラフィックを許可します。
3. 2番目のegressルールは、`kube-system` namespace内のすべてのコンポーネントへのegressトラフィックを許可することに焦点を当てており、これによりシステムnamespace内のコンポーネントとの他の重要な通信が可能になります。

この追加ポリシーを適用しましょう:

```bash wait=45
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpaths/operators/network-policies/allow-ui-egress.yaml
```

それでは、'catalog'サービスに接続できるかどうかをテストしてみましょう:

```bash
$ kubectl exec deployment/ui -n ui -- curl -s http://catalog.catalog/health | yq
OK
```

出力からわかるように、'catalog'サービスには接続できますが、`app.kubernetes.io/component: service`ラベルがないため、データベースには接続できません:

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* Failed to connect to catalog-mysql.catalog port 3306 after 5000 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5000 ms: Timeout was reached
command terminated with exit code 28
```

同様に、'order'サービスなどの他のサービスに接続できるかどうかをテストできます。接続できるはずです。ただし、インターネットや他のサードパーティサービスへの呼び出しはブロックされるはずです。

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v www.google.com --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
*   Trying [XXXX:XXXX:XXXX:XXXX::XXXX]:80...
* Immediate connect fail for XXXX:XXXX:XXXX:XXXX::XXXX: Network is unreachable
curl: (28) Failed to connect to www.google.com port 80 after 5001 ms: Timeout was reached
command terminated with exit code 28
```

これで'ui'コンポーネントに対する効果的なegressポリシーを定義したので、catalogサービスとデータベースコンポーネントに焦点を当て、'catalog' namespaceへのトラフィックを制御するネットワークポリシーを実装しましょう。

