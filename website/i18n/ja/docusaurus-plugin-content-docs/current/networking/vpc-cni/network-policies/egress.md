---
title: "出力コントロールの実装"
sidebar_position: 70
tmdTranslationSourceHash: a62afaa844733f1b13813f54947c5557
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

上記のアーキテクチャ図に示されているように、「ui」コンポーネントはフロントエンドアプリケーションです。そこで、「ui」コンポーネントのネットワークコントロールを実装するため、「ui」名前空間からのすべての出力トラフィックをブロックするネットワークポリシーを定義します。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/default-deny.yaml" paths="spec.podSelector,spec.policyTypes"}

1. 空のセレクタ `{}` はすべての Pod に一致します
2. `Egress` ポリシータイプは Pod からの送信トラフィックを制御します

> **注意** : ネットワークポリシーに名前空間が指定されていません。これはクラスター内の任意の名前空間に適用できる汎用ポリシーです。

```bash wait=30
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

では、「ui」コンポーネントから「catalog」コンポーネントにアクセスしてみましょう。

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -s http://catalog.catalog/health --connect-timeout 5
command terminated with exit code 28
```

curl コマンドを実行すると、以下のような出力が表示され、「ui」コンポーネントが「catalog」コンポーネントと直接通信できなくなったことがわかります。

```text
command terminated with exit code 28
```

上記のポリシーを実装すると、「ui」コンポーネントが「catalog」サービスや他のサービスコンポーネントへのアクセスを必要とするため、サンプルアプリケーションは正常に機能しなくなります。「ui」コンポーネントに効果的な出力ポリシーを定義するには、コンポーネントのネットワーク依存関係を理解する必要があります。

「ui」コンポーネントの場合、「catalog」、「orders」などの他のすべてのサービスコンポーネントと通信する必要があります。さらに、「ui」はクラスターシステム名前空間内のコンポーネントとも通信できる必要があります。例えば、「ui」コンポーネントが機能するには、DNS検索を実行する必要がありますが、これには`kube-system`名前空間内のCoreDNSサービスとの通信が必要です。

以下のネットワークポリシーは、上記の要件を念頭に置いて設計されました。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml" paths="spec.egress.0.to.0,spec.egress.0.to.1"}

1. 最初の出力ルールは、データベースコンポーネントへのアクセスを提供せずに、「catalog」、「orders」などのすべての`service`コンポーネントへの出力トラフィックを許可することに焦点を当てています。また、`namespaceSelector`を使用して、Pod のラベルが`app.kubernetes.io/component: service`に一致する限り、任意の名前空間への出力トラフィックを許可します。
2. 2番目の出力ルールは、`kube-system`名前空間内のすべてのコンポーネントへの出力トラフィックを許可することに焦点を当て、DNS検索やシステム名前空間内のコンポーネントとの他の重要な通信を可能にします。

この追加のポリシーを適用してみましょう：

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

次に、「catalog」サービスに接続できるかテストしてみましょう：

```bash
$ kubectl exec deployment/ui -n ui -- curl http://catalog.catalog/health
OK
```

出力から分かるように、「catalog」サービスには接続できるようになりましたが、データベースには`app.kubernetes.io/component: service`ラベルがないため接続できません：

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host catalog-mysql.catalog:3306 was resolved.
* IPv6: (none)
* IPv4: 172.16.244.252
*   Trying 172.16.244.252:3306...
  0     0    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0* Connection timed out after 5002 milliseconds
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* closing connection #0
curl: (28) Connection timed out after 5002 milliseconds
command terminated with exit code 28
```

同様に、「order」サービスなど他のサービスにも接続できるかテストできます。接続できるはずです。ただし、インターネットや他のサードパーティサービスへの呼び出しはブロックされるはずです。

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v www.google.com --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host www.google.com:80 was resolved.
* IPv6: 2001:4860:482a:7700::, 2001:4860:482d:7700::, 2001:4860:4828:7700::, 2001:4860:4826:7700::, 2001:4860:482c:7700::, 2001:4860:4827:7700::, 2001:4860:482b:7700::, 2001:4860:4829:7700::
* IPv4: 142.251.157.119, 142.251.152.119, 142.251.155.119, 142.251.156.119, 142.251.154.119, 142.251.150.119, 142.251.153.119, 142.251.151.119
*   Trying [2001:4860:482a:7700::]:80...
* Immediate connect fail for 2001:4860:482a:7700::: Network is unreachable
*   Trying [2001:4860:482d:7700::]:80...
* Immediate connect fail for 2001:4860:482d:7700::: Network is unreachable
...
...
*   Trying [2001:4860:4829:7700::]:80...
* Immediate connect fail for 2001:4860:4829:7700::: Network is unreachable
*   Trying 142.251.157.119:80...
  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0* ipv4 connect timeout after 2497ms, move on!
  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0*   Trying 142.251.152.119:80...
  0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0* ipv4 connect timeout after 1247ms, move on!
*   Trying 142.251.155.119:80...
* ipv4 connect timeout after 623ms, move on!
*   Trying 142.251.156.119:80...
* ipv4 connect timeout after 312ms, move on!
  0     0    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0*   Trying 142.251.154.119:80...
* Connection timed out after 5001 milliseconds
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* closing connection #0
curl: (28) Connection timed out after 5001 milliseconds
command terminated with exit code 28
```

「ui」コンポーネントの効果的な出力ポリシーを定義できたので、次は「catalog」サービスとデータベースコンポーネントに焦点を当て、「catalog」名前空間へのトラフィックを制御するネットワークポリシーを実装しましょう。

