---
title: "ラボセットアップ"
sidebar_position: 60
tmdTranslationSourceHash: 3a59d7db40ecf70a19c6ecceb2cf55c4
---

このラボでは、ラボクラスターにデプロイされたサンプルアプリケーションのネットワークポリシーを実装します。サンプルアプリケーションのコンポーネントアーキテクチャは以下のとおりです。

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

サンプルアプリケーションの各コンポーネントは、それぞれ独自の名前空間で実装されています。例えば、**'ui'**コンポーネントは**'ui'**名前空間にデプロイされ、**'catalog'**ウェブサービスと**'catalog'** MySQLデータベースは**'catalog'**名前空間にデプロイされています。

現在、ネットワークポリシーは定義されておらず、サンプルアプリケーションの任意のコンポーネントは他の任意のコンポーネントや外部サービスと通信できます。例えば、'catalog'コンポーネントは'checkout'コンポーネントと直接通信できます。これは以下のコマンドで確認できます：

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health
{"status":"ok","info":{},"error":{},"details":{}}
```

サンプルアプリケーションのトラフィックフローをより適切に制御できるように、いくつかのネットワークルールを実装していきましょう。
