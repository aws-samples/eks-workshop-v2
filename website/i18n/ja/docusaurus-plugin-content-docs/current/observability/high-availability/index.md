---
title: "EKSを使用したカオスエンジニアリング"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: Amazon EKSクラスターの回復力を確認するための様々な障害シナリオのシミュレーション。"
tmdTranslationSourceHash: f4f02238c6bb6f8894fe29117ebc3102
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください:

```bash timeout=900 wait=30
$ prepare-environment observability/resiliency
```

これにより、ラボ環境に以下の変更が適用されます:

- イングレスロードバランサーを作成
- RBACとRolebindingsを作成
- AWS Load Balancerコントローラーをインストール
- AWS Fault Injection Simulator（FIS）用のIAMロールを作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/.workshop/terraform)で確認できます。
:::

## 回復力とは何か？

クラウドコンピューティングにおける回復力とは、障害や通常の運用に対する課題に直面した際に、許容可能なパフォーマンスレベルを維持するシステムの能力を指します。以下を含みます:

1. **耐障害性**: 一部のコンポーネントが故障しても適切に動作し続ける能力。
2. **自己修復**: 障害を自動的に検出し回復する能力。
3. **スケーラビリティ**: リソースを追加することで増加した負荷を処理する能力。
4. **災害復旧**: 潜在的な災害に備え、そこから回復するプロセス。

## EKSで回復力が重要な理由は？

Amazon EKSはマネージドKubernetesプラットフォームを提供していますが、回復力のあるアーキテクチャを設計・実装することは依然として重要です。その理由は:

1. **高可用性**: システムの一部に障害が発生しても、アプリケーションにアクセス可能な状態を維持。
2. **データ整合性**: 予期せぬイベント中にデータ損失を防ぎ、一貫性を維持。
3. **ユーザーエクスペリエンス**: ダウンタイムやパフォーマンス低下を最小限に抑え、ユーザー満足度を維持。
4. **コスト効率**: 変動する負荷や部分的な障害に対応できるシステムを構築することで、過剰なプロビジョニングを回避。
5. **コンプライアンス**: 様々な業界におけるアップタイムとデータ保護の規制要件を満たす。

## ラボの概要と回復力シナリオ

このラボでは、様々な高可用性シナリオを探索し、EKS環境の回復力をテストします。一連の実験を通じて、異なるタイプの障害に対処し、Kubernetesクラスターがこれらの課題にどのように対応するかを理解するための実践的な経験を得ることができます。

シミュレーションと対応:

1. **ポッド障害**: ChaosMeshを使用して、個々のポッド障害に対するアプリケーションの回復力をテスト。
2. **ノード障害**: Kubernetesの自己修復能力を観察するためのノード障害シミュレーション。
   - AWS Fault Injection Simulatorなし: Kubernetesの自己修復能力を観察するための手動ノード障害シミュレーション。
   - AWS Fault Injection Simulatorあり: 部分的および完全なノード障害シナリオのためのAWS Fault Injection Simulatorの活用。

3. **アベイラビリティゾーン障害**: マルチAZデプロイメント戦略を検証するためのAZ全体の喪失シミュレーション。

## 学習内容

このチャプターの終わりには、以下のことができるようになります:

- AWS Fault Injection Simulator（FIS）を使用して、制御された障害シナリオをシミュレーションし学習する
- Kubernetesが異なるタイプの障害（ポッド、ノード、アベイラビリティゾーン）にどのように対処するかを理解する
- Kubernetesの自己修復能力の実際の動作を観察する
- EKS環境におけるカオスエンジニアリングの実践的経験を得る

これらの実験は以下の理解に役立ちます:

- Kubernetesが異なるタイプの障害にどのように対処するか
- 適切なリソース割り当てとポッド配分の重要性
- モニタリングとアラートシステムの有効性
- アプリケーションの耐障害性と回復戦略の改善方法

## ツールとテクノロジー

このチャプターでは、以下を使用します:

- 制御されたカオスエンジニアリングのためのAWS Fault Injection Simulator（FIS）
- Kubernetesネイティブなカオステスト用のChaos Mesh
- カナリアの作成と監視のためのAWS CloudWatch Synthetics
- 障害発生時のポッドとノードの挙動を観察するためのKubernetesネイティブ機能

## カオスエンジニアリングの重要性

カオスエンジニアリングとは、システムの弱点を特定するために意図的に制御された障害を導入する実践です。システムの回復力を積極的にテストすることで、以下のことができます:

1. ユーザーに影響する前に隠れた問題を発見する
2. 乱れた条件に耐えるシステムの能力に自信を持つ
3. インシデント対応手順を改善する
4. 組織内に回復力の文化を育てる

このラボの終わりには、EKS環境の高可用性機能と改善が必要な分野について包括的な理解を得ることができます。

:::info
AWS回復力機能についてより詳しい情報は、以下を確認することをお勧めします:

- [イングレスロードバランサー](/docs/fundamentals/exposing/ingress/)
- [KubernetesのRBACとの統合](/docs/security/cluster-access-management/kubernetes-rbac)
- [AWS Fault Injection Simulator](https://aws.amazon.com/fis/)
- [Amazon EKSでの回復力のあるワークロードの運用](https://aws.amazon.com/blogs/containers/operating-resilient-workloads-on-amazon-eks/)

:::
