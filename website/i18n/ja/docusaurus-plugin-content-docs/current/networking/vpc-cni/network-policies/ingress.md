---
title: "Implementing Ingress Controls"
sidebar_position: 80
tmdTranslationSourceHash: 5e7b8c2d4eeeec35a7ce285e35982319
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

アーキテクチャ図に示されているように、「catalog」名前空間は「ui」名前空間からのトラフィックのみを受け取り、他の名前空間からは受け取りません。また、「catalog」データベースコンポーネントは「catalog」サービスコンポーネントからのトラフィックのみを受け取ることができます。

「catalog」名前空間へのトラフィックを制御するイングレスネットワークポリシーを実装することから始めましょう。

ポリシーを適用する前に、「catalog」サービスは「ui」コンポーネントからアクセスできます：

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

同様に、「orders」コンポーネントからもアクセスできます：

```bash
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

ここで、「ui」コンポーネントからのみ「catalog」サービスコンポーネントへのトラフィックを許可するネットワークポリシーを定義します：

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector`は、ラベル`app.kubernetes.io/name: catalog`と`app.kubernetes.io/component: service`を持つポッドをターゲットにします
2. この`ingress.from`設定は、ラベル`app.kubernetes.io/name: ui`を持ち、`kubernetes.io/metadata.name: ui`で識別される`ui`名前空間で実行されているポッドからの受信接続のみを許可します

ポリシーを適用しましょう：

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

これで、「ui」から「catalog」コンポーネントにアクセスできることを確認してポリシーを検証できます：

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
  Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

しかし、「orders」コンポーネントからはアクセスできません：

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```

上記の出力からわかるように、「ui」コンポーネントだけが「catalog」サービスコンポーネントと通信でき、「orders」サービスコンポーネントはできません。

しかし、これはまだ「catalog」データベースコンポーネントを開放したままにしています。そこで、「catalog」サービスコンポーネントだけが「catalog」データベースコンポーネントと通信できるようにするネットワークポリシーを実装しましょう。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector`は、ラベル`app.kubernetes.io/name: catalog`と`app.kubernetes.io/component: mysql`を持つポッドをターゲットにします
2. `ingress.from`は、ラベル`app.kubernetes.io/name: catalog`と`app.kubernetes.io/component: service`を持つポッドからの受信接続のみを許可します

ポリシーを適用しましょう：

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

「orders」コンポーネントから「catalog」データベースに接続できないことを確認することで、ネットワークポリシーを検証してみましょう：

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
command terminated with exit code 28
...
```

しかし、「catalog」ポッドを再起動すると、まだ接続することができます：

```bash
$ kubectl rollout restart deployment/catalog -n catalog
$ kubectl rollout status deployment/catalog -n catalog --timeout=2m
```

上記の出力からわかるように、「catalog」サービスコンポーネントのみが「catalog」データベースコンポーネントと通信できるようになりました。

これで「catalog」名前空間に効果的なイングレスポリシーを実装したので、同じロジックをサンプルアプリケーションの他の名前空間とコンポーネントに拡張し、サンプルアプリケーションの攻撃対象領域を大幅に減らし、ネットワークセキュリティを向上させることができます。
