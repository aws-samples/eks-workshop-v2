---
title: "仕組み"
sidebar_position: 5
tmdTranslationSourceHash: 318ab5fd6c8856bb1f1e75f36368450c
---

Crossplaneはクラスター内で主に2つのコンポーネントを使用して動作します：

1. コア機能を提供するCrossplaneコントローラー
2. 1つ以上のCrossplaneプロバイダー（それぞれがAWSなどの特定のプロバイダーと統合するためのコントローラーとカスタムリソース定義を提供）

EKSクラスターには、Crossplaneコントローラー、Upbound AWSプロバイダー、および必要なコンポーネントが事前にインストールされています。これらは`crossplane-system`名前空間内で`crossplane-rbac-manager`と共にデプロイメントとして実行されています：

```bash
$ kubectl get deployment -n crossplane-system
NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
crossplane                                   1/1     1            1           3h7m
crossplane-rbac-manager                      1/1     1            1           3h7m
upbound-aws-provider-dynamodb-23a48a51e223   1/1     1            1           3h6m
upbound-provider-family-aws-1ac09674120f     1/1     1            1           21h
```

ここで、`upbound-provider-family-aws`はUpboundによって開発・サポートされているAmazon Web Services（AWS）用のCrossplaneプロバイダーを表します。`upbound-aws-provider-dynamodb`はCrossplaneを通じてDynamoDBをデプロイするための専用サブセットです。

Crossplaneは、開発者がKubernetesマニフェスト（クレームと呼ばれる）を使用してインフラストラクチャリソースをリクエストするプロセスを簡素化します。下図に示すように、クレームは名前空間スコープの唯一のCrossplaneリソースであり、開発者インターフェースとして機能し、実装の詳細を抽象化します。クレームがクラスターにデプロイされると、コンポジットリソース（XR）が作成されます。これはKubernetesカスタムリソースで、コンポジションと呼ばれるテンプレートを通じて定義された1つ以上のクラウドリソースを表します。コンポジットリソースは次に1つ以上のマネージドリソースを作成し、これらがAWS APIと対話して目的のインフラストラクチャリソースの作成をリクエストします。

![Crossplane claim](/docs/automation/controlplanes/crossplane/claim-architecture-drawing.webp)

このアーキテクチャにより、高レベルの抽象化（クレーム）を扱う開発者と、基盤となるインフラストラクチャの実装（コンポジションとマネージドリソース）を定義するプラットフォームチームの間で、明確な関心の分離が可能になります。
