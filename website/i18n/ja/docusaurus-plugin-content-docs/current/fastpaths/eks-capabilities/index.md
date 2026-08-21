---
title: "Capability Essentials"
sidebar_position: 70
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: "1f4c997776bef981a8e75f9de338e3ea"
---

::required-time{estimatedLabExecutionTimeMinutes="14"}

:::tip 始める前に
このファストパスは、専用の Amazon EKS Auto Mode クラスターを使用します。Amazon EKS Auto Mode は、クラスター自体を超えて Kubernetes クラスターの AWS 管理を拡張し、コンピュートのオートスケーリング、ネットワーキング、ロードバランシング、DNS、ブロックストレージなど、ワークロードのスムーズな運用を可能にするインフラストラクチャを管理します。

このラボ用に環境を準備します:

```bash timeout=1800
$ prepare-environment fastpaths/eks-capabilities
```

これにより、3つのマネージド Capability とそれらをサポートするインフラストラクチャがプロビジョニングされるため、約7〜10分かかります。Capability がアクティブ化される間、コマンドがアイドル状態に見えるのは正常です。
:::

**Capability Essentials** へようこそ。プラットフォームエンジニアと DevOps ペルソナを対象とした、ハンズオンのファストパスです。[Amazon EKS Capabilities](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/) に付属する Capability を使用して、小売サンプルアプリケーション全体で一貫したストーリーを展開します。

各 Capability は完全マネージド型のコントロールプレーンコンポーネントです。コントローラーは、ワーカーノード上ではなく、クラスターとは別の AWS 所有のインフラストラクチャで実行され、AWS がそのスケーリング、パッチ適用、アップグレードを処理します。Helm インストール、スケールするコントローラー Deployment、コントローラー用の Pod レベルの IRSA は不要です。Capability 自体が作業を行うために IAM role を引き受けるからです。

:::info
Amazon EKS Capabilities は、プラットフォームコンポーネントの運用を AWS にオフロードするため、プラットフォームインフラストラクチャの維持ではなく、アプリケーションのデプロイに集中できます。詳細については、[Amazon EKS Capabilities のアナウンス](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/)をご覧ください。
:::

## 構築する内容

| Capability  | 実行する内容                                                                                                                                                                                                                                                                  |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ACK** (AWS Controllers for Kubernetes) | `Table` リソースを適用して、Kubernetes から実際の Amazon DynamoDB テーブルをプロビジョニングし、`carts` マイクロサービスをクラスター内のモックから EKS Pod Identity を介して AWS マネージドテーブルに移行します。                                                                     |
| **Argo CD** | 事前にプロビジョニングされた AWS CodeCommit リポジトリから GitOps を介して `catalog` マイクロサービスをデリバリーします。AWS IAM Identity Center を通じてマネージド Argo CD UI にサインインし、クラスターをデプロイターゲットとして登録してから、実際の GitOps 更新をトリガーします。 |
| **kro** (Kube Resource Orchestrator) | ACK ラボの3つの適用ステップを単一の `CartsStack` リソースに統合します。Namespace、ACK `Table`、ConfigMap、ServiceAccount をバンドルする `ResourceGraphDefinition` を定義し、1つのインスタンスを適用して kro がグラフ全体を調整するのを確認します。                  |

Argo CD ラボは AWS IAM Identity Center を通じてサインインし、短時間の一回限りのコンソール設定が含まれます。これについては、[Identity Center を介して Argo CD にサインイン](./argocd/signin-argocd.md)ページで説明されています。

## 事前にプロビジョニングされている内容

`prepare-environment` の終了時点で、クラスターには以下が含まれています:

| リソース | 状態 |
| --- | --- |
| **ACK capability** | `ACTIVE`、DynamoDB コントローラーの Custom Resource Definitions (CRD) がクラスターに登録済み |
| **Argo CD capability** | `ACTIVE`、サインイン用に AWS IAM Identity Center とフェデレーションされ、管理者グループとユーザーが Argo CD `ADMIN` ロールにマッピング済み |
| **kro capability** | `ACTIVE`、kro ラボで使用するための `resourcegraphdefinitions.kro.run` CRD が登録済み |
| **CodeCommit リポジトリ** | Argo CD が調整できるように `catalog` Kubernetes マニフェストで事前シード済み |
| **IAM Capability Roles** | 各 Capability に1つずつ、各 Capability が必要とする AWS API にスコープ設定済み |
| **`carts` 用の Pod Identity role** | `${EKS_CLUSTER_AUTO_NAME}-carts-*` にワイルドカードスコープ設定済み、同じロールが ACK ラボの `-carts-fastpath` テーブルと kro ラボの `-carts-kro` テーブルの両方を変更なしでカバー |
| **共有ファストパスアドオン** | KEDA、fluent-bit、External Secrets、開発者およびオペレーターファストパスのプロビジョニングから継承 |

各 Capability は、クラスター外の AWS マネージドインフラストラクチャで実行されます。クラスター内で確認できるのは、CRD と各 Capability が登録するマネージド Namespace のみであり、これに対して適用を行います。

それでは始めましょう。

