---
title: "ラボのセットアップ"
sidebar_position: 60
tmdTranslationSourceHash: '9eba6c5d1669ba133f53bbc555f31bb3'
---

このラボでは、ラボクラスターにデプロイされたサンプルアプリケーションのネットワークポリシーを実装します。サンプルアプリケーションのコンポーネントアーキテクチャを以下に示します。

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

サンプルアプリケーションの各コンポーネントは、独自の namespace に実装されています。例えば、**'ui'** コンポーネントは **'ui'** namespace にデプロイされ、**'catalog'** Web サービスと **'catalog'** MySQL データベースは **'catalog'** namespace にデプロイされています。

現在、定義されたネットワークポリシーはなく、サンプルアプリケーション内のどのコンポーネントも他のコンポーネントや外部サービスと通信できます。例えば、'catalog' コンポーネントは 'checkout' コンポーネントと直接通信できます。以下のコマンドを使用してこれを検証できます。

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health | jq
{
  "status": "ok",
  "info": {
    "chaos": {
      "status": "up"
    }
  },
  "error": {},
  "details": {
    "chaos": {
      "status": "up"
    }
  }
}
```

EKS Auto Mode クラスターでネットワークポリシーを有効にするために必要な構成変更を行いましょう。そのために、クラスターにネットワーキングを提供する VPC container network interface (CNI) の ConfigMap を作成します。

::yaml{file="manifests/modules/fastpaths/operators/network-policies/vpc-cni-policies.yaml" paths="data.enable-network-policy-controller"}

1. これにより、vpc-cni プラグインでネットワークポリシーコントローラが有効になります

この構成を適用します。

```bash timeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpaths/operators/network-policies/vpc-cni-policies.yaml
```

それでは、サンプルアプリケーションのネットワークトラフィックフローをより適切に制御できるように、いくつかのネットワークルールを実装しましょう。

