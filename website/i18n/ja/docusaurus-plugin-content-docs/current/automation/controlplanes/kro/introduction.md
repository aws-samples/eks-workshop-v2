---
title: "はじめに"
sidebar_position: 3
tmdTranslationSourceHash: 59f42c036157964a2d6c6987fb563967
---

kro はクラスター内で2つの主要コンポーネントを使用して動作します：

1. kro コントローラーマネージャー（コアのオーケストレーション機能を提供）
2. ResourceGraphDefinitions（RGDs）（関連リソースのグループを作成するためのテンプレートを定義）

kro コントローラーマネージャーは ResourceGraphDefinition カスタムリソースを監視し、テンプレートで定義された基盤となる Kubernetes リソースの作成と管理をオーケストレーションします。

kro は、プラットフォームチームが複数の関連リソースをカプセル化する ResourceGraphDefinitions を定義できるようにすることで、複雑なリソース管理を簡素化します。開発者は RGD スキーマによって定義されたシンプルなカスタム API を操作し、kro が基礎となるリソースの作成と管理の複雑さを処理します。このアーキテクチャにより、ResourceGraphDefinitions を定義するプラットフォームチームと、複雑なリソースグループを作成するためのシンプルなカスタム API を消費するアプリケーション開発者との間に明確な分離が提供されます。

まず、Helm チャートを使用して kro を Kubernetes クラスターにインストールしましょう：

```bash wait=60
$ helm install kro oci://ghcr.io/kro-run/kro/kro \
  --version=${KRO_VERSION} \
  --namespace kro-system --create-namespace \
  --wait
```

kro コントローラーが実行されていることを確認します：

```bash
$ kubectl get deployment -n kro-system
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
kro     1/1     1            1           13s
```

また、kro カスタムリソース定義がインストールされていることも確認できます：

```bash
$ kubectl get crd | grep kro
resourcegraphdefinitions.kro.run          2025-10-15T22:34:13Z
```

ResourceGraphDefinition を作成すると、kro は以下を実行します：

1. **新しいカスタム API の登録** - RGD で定義されたスキーマに基づいて、kro は開発者が使用できる新しい Kubernetes CRD を自動的に作成します
2. **リソースインスタンスの処理** - 開発者がカスタム API のインスタンスを作成すると、kro は定義されたテンプレートを使用してリクエストを処理します
3. **CEL 式の評価** - kro は Common Expression Language（CEL）を使用して条件を評価し、リソース間で値を受け渡し、作成順序を決定します
4. **インテリジェントな依存関係の処理** - kro はリソースがお互いをどのように参照するかを自動的に分析し、手動設定なしに最適なデプロイ順序を決定します
5. **管理リソースの作成** - テンプレートと依存関係分析に基づいて、kro は指定された Kubernetes リソースを正しい順序で作成します
6. **関係の維持** - kro はリソース間の依存関係を追跡し、適切なライフサイクル管理を確実にします
