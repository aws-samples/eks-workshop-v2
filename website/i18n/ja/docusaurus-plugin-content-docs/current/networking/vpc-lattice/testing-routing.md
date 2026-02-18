---
title: "トラフィックルーティングのテスト"
sidebar_position: 40
tmdTranslationSourceHash: b2448e7873e3d3d002a0fb5f392da6c5
---

実際の環境では、カナリアデプロイメントは定期的に一部のユーザーに機能をリリースするために使用されます。このシナリオでは、人為的にトラフィックの75%を新しいバージョンのチェックアウトサービスにルーティングしています。カートに異なるオブジェクトを入れて複数回チェックアウト手順を完了すると、ユーザーに2つのバージョンのアプリケーションが表示されるはずです。

まず、Kubernetes `exec`を使用して、UIポッドからLatticeサービスURLが機能することを確認しましょう。これは`HTTPRoute`リソースのアノテーションから取得します：

```bash
$ export CHECKOUT_ROUTE_DNS="http://$(kubectl get httproute checkoutroute -n checkout -o json | jq -r '.metadata.annotations["application-networking.k8s.aws/lattice-assigned-domain-name"]')"
$ echo "Checkout Lattice DNS is $CHECKOUT_ROUTE_DNS"
$ POD_NAME=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec $POD_NAME -n ui -- curl -s $CHECKOUT_ROUTE_DNS/health
{"status":"ok","info":{},"error":{},"details":{}}
```

次に、UIコンポーネントの`ConfigMap`をパッチして、UIサービスをVPC Latticeサービスエンドポイントに向けるようにします：

```kustomization
modules/networking/vpc-lattice/ui/configmap.yaml
ConfigMap/ui
```

この設定変更を行いましょう：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/vpc-lattice/ui/ \
  | envsubst | kubectl apply -f -
```

次に、UIコンポーネントのポッドを再起動します：

```bash
$ kubectl rollout restart deployment/ui -n ui
$ kubectl rollout status deployment/ui -n ui
```

ブラウザを使用してアプリケーションにアクセスしてみましょう。`ui`ネームスペースには`ui-nlb`という名前の`LoadBalancer`タイプのサービスが提供されており、そこからアプリケーションのUIにアクセスできます。

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

ブラウザでこのURLにアクセスし、複数回チェックアウトを試してみてください（カートに異なるアイテムを入れてみてください）：

![チェックアウト例](/docs/networking/vpc-lattice/examplecheckout.webp)

チェックアウト時に「Lattice checkout」ポッドが約75%の確率で使用されていることに気づくでしょう：

![Latticeチェックアウト](/docs/networking/vpc-lattice/latticecheckout.webp)

