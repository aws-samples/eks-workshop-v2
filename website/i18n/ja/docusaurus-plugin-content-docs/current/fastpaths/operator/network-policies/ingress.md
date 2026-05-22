---
title: "Ingress コントロールの実装"
sidebar_position: 80
tmdTranslationSourceHash: 'b4ba9980ff48dda0f8bd740131f20534'
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

アーキテクチャ図に示されているように、'catalog' namespace は 'ui' namespace からのみトラフィックを受信し、他の namespace からは受信しません。また、'catalog' データベースコンポーネントは、'catalog' サービスコンポーネントからのみトラフィックを受信できます。

上記のネットワークルールを、'catalog' namespace へのトラフィックを制御する Ingress ネットワークポリシーを使用して実装していきます。

ポリシーを適用する前は、'catalog' サービスは 'ui' コンポーネントからアクセスできます：

```bash timeout=180
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

'orders' コンポーネントからもアクセスできます：

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

次に、'catalog' サービスコンポーネントへのトラフィックを 'ui' コンポーネントからのみ許可するネットワークポリシーを定義します：

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector` はラベル `app.kubernetes.io/name: catalog` と `app.kubernetes.io/component: service` を持つ Pod をターゲットにします
2. この `ingress.from` 設定は、`kubernetes.io/metadata.name: ui` で識別される `ui` namespace で実行され、ラベル `app.kubernetes.io/name: ui` を持つ Pod からの受信接続のみを許可します

ポリシーを適用しましょう：

```bash wait=45
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

次に、'ui' から 'catalog' コンポーネントに引き続きアクセスできることを確認してポリシーを検証します：

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

しかし、'orders' コンポーネントからはアクセスできません：

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```

上記の出力からわかるように、'ui' コンポーネントのみが 'catalog' サービスコンポーネントと通信でき、'orders' サービスコンポーネントは通信できません。

しかし、これでは 'catalog' データベースコンポーネントがまだ開いたままなので、'catalog' サービスコンポーネントのみが 'catalog' データベースコンポーネントと通信できるようにするネットワークポリシーを実装しましょう。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector` はラベル `app.kubernetes.io/name: catalog` と `app.kubernetes.io/component: mysql` を持つ Pod をターゲットにします
2. `ingress.from` はラベル `app.kubernetes.io/name: catalog` と `app.kubernetes.io/component: service` を持つ Pod からの受信接続のみを許可します

ポリシーを適用しましょう：

```bash wait=45
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

'orders' コンポーネントから 'catalog' データベースに接続できないことを確認してネットワークポリシーを検証しましょう：

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
command terminated with exit code 28
...
```

重要な点として、ネットワークポリシーは IP アドレスに依存していないことに注意してください。'catalog' Pod を再起動して、引き続き接続できることを確認できます：

```bash timeout=180
$ kubectl rollout restart deployment/catalog -n catalog
$ kubectl rollout status deployment/catalog -n catalog --timeout=2m
```

次に、'catalog' Pod から 'catalog-mysql' データベースに接続できるか確認しましょう。

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -v catalog-mysql.catalog:3306 --connect-timeout 5 --http0.9
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host catalog-mysql.catalog:3306 was resolved.
* IPv6: (none)
* IPv4: 172.20.233.240
*   Trying 172.20.233.240:3306...
* Connected to catalog-mysql.catalog (172.20.233.240) port 3306
* using HTTP/1.x
> GET / HTTP/1.1
> Host: catalog-mysql.catalog:3306
> User-Agent: curl/8.11.1
> Accept: */*
> 
* Request completely sent off
{ [5 bytes data]
100   115    0   115    0     0  20901      0 --:--:-- --:--:-- --:--:-- 23000
* shutting down connection #0
```

上記の出力からわかるように、'catalog' サービスコンポーネントのみが 'catalog' データベースコンポーネントと通信できます。

これで 'catalog' namespace に対する効果的な Ingress ポリシーを実装できたので、同じロジックをサンプルアプリケーションの他の namespace やコンポーネントに拡張することで、サンプルアプリケーションの攻撃対象領域を大幅に削減し、ネットワークセキュリティを向上させることができます。

