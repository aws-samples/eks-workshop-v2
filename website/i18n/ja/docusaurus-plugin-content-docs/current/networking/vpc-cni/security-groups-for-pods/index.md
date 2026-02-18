---
title: "Security Groups for Pods"
sidebar_position: 20
weight: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service上のPodとの間のインバウンドおよびアウトバウンドトラフィックをAmazon EC2セキュリティグループで制御します。"
tmdTranslationSourceHash: 2e744b7e7ed933443ac0a65be866b7fb
---

::required-time

:::tip 開始する前に
このセクションのための環境を準備してください：

```bash timeout=900 wait=30
$ prepare-environment networking/securitygroups-for-pods
```

これにより、ラボ環境に以下の変更が加えられます：

- Amazon Relational Database Serviceインスタンスの作成
- RDSインスタンスへのアクセスを許可するAmazon EC2セキュリティグループの作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/securitygroups-for-pods/.workshop/terraform)で確認できます。

:::

セキュリティグループは、インスタンスレベルのネットワークファイアウォールとして機能し、AWSクラウドデプロイメントにおいて最も重要かつ一般的に使用される構成要素の一つです。コンテナ化されたアプリケーションは、クラスター内で実行されている他のサービスや、Amazon Relational Database Service（Amazon RDS）やAmazon ElastiCacheなどの外部AWSサービスへのアクセスを頻繁に必要とします。AWSでは、サービス間のネットワークレベルのアクセス制御は、多くの場合、EC2セキュリティグループを通じて実現されています。

デフォルトでは、Amazon VPC CNIはノード上のプライマリENIに関連付けられたセキュリティグループを使用します。具体的には、インスタンスに関連付けられたすべてのENIは同じEC2セキュリティグループを持ちます。したがって、ノード上のすべてのPodは、それが実行されているノードと同じセキュリティグループを共有します。Security Groups for Podsを使用すると、ネットワークセキュリティ要件が異なるアプリケーションを共有コンピューティングリソース上で実行することで、ネットワークセキュリティコンプライアンスを容易に達成できます。Pod間およびPodから外部AWSサービスへのトラフィックに対するネットワークセキュリティルールは、EC2セキュリティグループで一箇所で定義し、KubernetesネイティブAPIを使用してアプリケーションに適用することができます。Podレベルでセキュリティグループを適用した後、アプリケーションとノードグループのアーキテクチャは以下のように簡素化できます。

VPC CNIの`ENABLE_POD_ENI=true`を設定することで、Security Groups for Podsを有効化できます。Pod ENIを有効にすると、コントロールプレーン（EKSによって管理される）で実行されている[VPC Resource Controller](https://github.com/aws/amazon-vpc-resource-controller-k8s)が、「aws-k8s-trunk-eni」と呼ばれるトランクインターフェースを作成し、ノードにアタッチします。トランクインターフェースはインスタンスにアタッチされた標準のネットワークインターフェースとして機能します。

コントローラーはまた、「aws-k8s-branch-eni」という名前のブランチインターフェースを作成し、それをトランクインターフェースに関連付けます。Podは[SecurityGroupPolicy](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/config/crd/bases/vpcresources.k8s.aws_securitygrouppolicies.yaml) Custom Resource Definitionを使用してセキュリティグループが割り当てられ、ブランチインターフェースに関連付けられます。セキュリティグループはネットワークインターフェースで指定されるため、特定のセキュリティグループを必要とするPodをこれらの追加のネットワークインターフェースにスケジュールできるようになりました。推奨事項は[EKSベストプラクティスガイド](https://aws.github.io/aws-eks-best-practices/networking/sgpp/)を、デプロイ前提条件は[EKSユーザーガイド](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html)を参照してください。

![Insights](/docs/networking/vpc-cni/security-groups-for-pods/overview.webp)

この章では、サンプルアプリケーションコンポーネントの1つを再構成して、外部ネットワークリソースにアクセスするためにSecurity Groups for Podsを活用します。

