---
title: "Ingress の検証"
sidebar_position: 15
tmdTranslationSourceHash: 8a28d3742a419e199682562031c057ff
---

ラボの前提条件の一部として、Ingress リソースが作成され、AWS Load Balancer Controller は Ingress 設定に基づいて対応する ALB を作成しました。ALB がプロビジョニングされ、そのターゲットを登録するには数分かかります。続行する前に Ingress リソースと ALB を検証しましょう。

作成された Ingress オブジェクトを調べてみましょう:

```bash hook=validate-ingress hookTimeout=430
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                                      PORTS   AGE
ui     alb     *       k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com   80      3m51s
```

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
Waiting for k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com
```

プロビジョニングが完了したら、Web ブラウザでアクセスできます。Web ストアの UI が表示され、ユーザーとしてサイト内を移動できるようになります。

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
