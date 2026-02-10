---
title: マネージドノードグループ
sidebar_position: 10
tmdTranslationSourceHash: 164445147875a1ed08f67c28502a8175
---

EKS クラスターには、Pod がスケジュールされる 1 つ以上の EC2 ノードが含まれています。EKS ノードは AWS アカウント内で実行され、クラスター API サーバーエンドポイントを通じてクラスターのコントロールプレーンに接続します。ノードグループに 1 つ以上のノードをデプロイします。ノードグループは、EC2 Auto Scaling グループにデプロイされる 1 つ以上の EC2 インスタンスです。

EKS ノードは標準的な Amazon EC2 インスタンスです。EC2 の料金に基づいて課金されます。詳細については、[Amazon EC2 の料金](https://aws.amazon.com/ec2/pricing/)を参照してください。

[Amazon EKS マネージドノードグループ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)は、Amazon EKS クラスター用のノードのプロビジョニングとライフサイクル管理を自動化します。これにより、新しい AMI や Kubernetes バージョンのデプロイメントのローリングアップデートなどの運用アクティビティが大幅に簡素化されます。

![Managed Node Groups](/docs/fundamentals/compute/managed-node-groups/managed-node-groups.webp)

Amazon EKS マネージドノードグループを実行する利点には以下が含まれます：

- Amazon EKS コンソール、`eksctl`、AWS CLI、AWS API、または AWS CloudFormation や Terraform などのインフラストラクチャアズコードツールを使用して、1 つの操作でノードの作成、自動更新、または終了が可能
- プロビジョニングされたノードは最新の Amazon EKS 最適化 AMI を使用して実行される
- MNG の一部としてプロビジョニングされたノードは、アベイラビリティーゾーン、CPU アーキテクチャ、インスタンスタイプなどのメタデータで自動的にタグ付けされる
- ノードの更新と終了は自動的かつ適切にノードをドレインし、アプリケーションが利用可能な状態を維持することを保証する
- Amazon EKS マネージドノードグループの使用に追加料金はなく、プロビジョニングされた AWS リソースに対してのみ支払う

このセクションのラボでは、EKS マネージドノードグループを使用してクラスターにコンピューティング容量を提供するさまざまな方法について説明します。

