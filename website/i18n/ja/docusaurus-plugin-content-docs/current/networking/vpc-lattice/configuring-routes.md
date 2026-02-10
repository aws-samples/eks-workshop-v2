---
title: "ルートの設定"
sidebar_position: 30
tmdTranslationSourceHash: 2a099daa7d22fd6797d5afed142a0f8d
---

このセクションでは、ブルー/グリーンデプロイメントやカナリアスタイルのデプロイメントのための重み付けルーティングを使用した、高度なトラフィック管理にAmazon VPC Latticeを使用する方法を示します。

配送オプションに「Lattice」というプレフィックスを追加した`checkout`マイクロサービスの修正版をデプロイしましょう。Kustomizeを使用して、この新しいバージョンを新しい名前空間（`checkoutv2`）にデプロイします。

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/abtesting/
$ kubectl rollout status deployment/checkout -n checkoutv2
```

`checkoutv2`名前空間には、アプリケーションの2番目のバージョンが含まれるようになりましたが、`checkout`名前空間の同じ`redis`インスタンスを使用しています。

```bash
$ kubectl get pods -n checkoutv2
NAME                        READY   STATUS    RESTARTS   AGE
checkout-854cd7cd66-s2blp   1/1     Running   0          26s
```

次に、`HTTPRoute`リソースを作成して重み付けルーティングがどのように機能するかを実演しましょう。まず、Latticeが私たちのcheckoutサービスで適切なヘルスチェックを実行する方法を指示する`TargetGroupPolicy`を作成します：

::yaml{file="manifests/modules/networking/vpc-lattice/target-group-policy/target-group-policy.yaml" paths="spec.targetRef,spec.healthCheck,spec.healthCheck.intervalSeconds,spec.healthCheck.timeoutSeconds,spec.healthCheck.healthyThresholdCount,spec.healthCheck.unhealthyThresholdCount,spec.healthCheck.path,spec.healthCheck.port,spec.healthCheck.protocol,spec.healthCheck.statusMatch"}

1. `targetRef`はこのポリシーを`checkout`Serviceに適用します
2. `healthCheck`セクションの設定はVPC Latticeがサービスの健全性をどのように監視するかを定義します
3. `intervalSeconds: 10`：10秒ごとにチェック
4. `timeoutSeconds: 1`：チェックごとに1秒のタイムアウト
5. `healthyThresholdCount: 3`：3回連続成功＝健全
6. `unhealthyThresholdCount: 2`：2回連続失敗＝不健全
7. `path: "/health"`：ヘルスチェックエンドポイントのパス
8. `port: 8080`：ヘルスチェックエンドポイントのポート
9. `protocol: HTTP`：ヘルスチェックエンドポイントのプロトコル
10. `statusMatch: "200"`：HTTP 200レスポンスを期待

このリソースを適用します：

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/target-group-policy
```

次に、`checkoutv2`に75％のトラフィックを、残りの25％のトラフィックを`checkout`に分散するKubernetes `HTTPRoute`ルートを作成します：

::yaml{file="manifests/modules/networking/vpc-lattice/routes/checkout-route.yaml" paths="spec.parentRefs.0,spec.rules.0.backendRefs.0,spec.rules.0.backendRefs.1"}

1. `parentRefs`はこの`HTTPRoute`ルートを`${EKS_CLUSTER_NAME}`という名前のゲートウェイの`http`リスナーに接続します
2. この`backendRefs`ルールはトラフィックの`25%`を`checkout`名前空間の`checkout`Serviceのポート`80`に送信します
3. この`backendRefs`ルールはトラフィックの`75%`を`checkoutv2`名前空間の`checkout`Serviceのポート`80`に送信します

このリソースを適用します：

```bash hook=route
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/routes/checkout-route.yaml \
  | envsubst | kubectl apply -f -
```

関連するリソースの作成には2〜3分かかることがあります。完了を待つために次のコマンドを実行してください：

```bash wait=10 timeout=400
$ kubectl wait -n checkout --timeout=3m \
  --for=jsonpath='{.metadata.annotations.application-networking\.k8s\.aws\/lattice-assigned-domain-name}' httproute/checkoutroute
```

完了すると、`HTTPRoute`のDNS名を`HTTPRoute`アノテーション`application-networking.k8s.aws/lattice-assigned-domain-name`から見つけることができます：

```bash
$ kubectl describe httproute checkoutroute -n checkout
Name:         checkoutroute
Namespace:    checkout
Labels:       <none>
Annotations:  application-networking.k8s.aws/lattice-assigned-domain-name:
                checkoutroute-checkout-0d8e3f4604a069e36.7d67968.vpc-lattice-svcs.us-east-2.on.aws
API Version:  gateway.networking.k8s.io/v1beta1
Kind:         HTTPRoute
...
```

これで、Latticeリソースの下に作成された関連Serviceを[VPC Latticeコンソール](https://console.aws.amazon.com/vpc/home#Services)で確認できます。
![CheckoutRouteサービス](/docs/networking/vpc-lattice/checkoutroute.webp)

:::tip トラフィックは現在Amazon VPC Latticeによって処理されています
Amazon VPC Latticeは、異なるVPCを含む任意のソースからこのサービスへのトラフィックを自動的にリダイレクトできるようになりました！また、他のVPC Latticeの[機能](https://aws.amazon.com/vpc/lattice/features/)も十分に活用できます。
:::
