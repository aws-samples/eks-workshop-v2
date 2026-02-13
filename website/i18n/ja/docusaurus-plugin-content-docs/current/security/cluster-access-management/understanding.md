---
title: "Cluster Access Management APIの理解"
sidebar_position: 11
tmdTranslationSourceHash: 8aa7ba79d55267c9c14e17689f94ef87
---

Amazon EKSクラスターを作成する際、プラットフォームを消費および管理するチームやユーザーにアクセス権を付与する必要があります。チームによって必要なアクセスレベルは異なります - プラットフォームエンジニアはリソースを管理し、アドオンをデプロイしたり問題をトラブルシューティングするためにクラスター全体のアクセス権が必要かもしれませんが、開発者はアプリケーションが存在するNamespaceに限定された読み取り専用アクセスまたは管理者アクセスのみが必要な場合があります。

いずれの場合も、Amazon EKSクラスターへのアクセスを制御するために、それらのチームやユーザーに紐づけられたアイデンティティまたはプリンシパルの集中認証（AuthN）を提供するソリューションが必要です。このソリューションはKubernetesのロールベースアクセス制御（RBAC）と統合して、最小権限の原則に従いながら、より細かな方法で各チームに必要な特定の認可（AuthZ）レベルを付与する必要があります。

Cluster Access Management APIは、Amazon EKS v1.23以降のクラスター（新規および既存の両方）で利用可能なAWS APIの機能です。これはAWS IAMとKubernetes RBACの間のアイデンティティマッピングを簡素化し、アクセス管理のためにAWSとKubernetes APIを切り替える必要性をなくし、運用上のオーバーヘッドを削減します。このツールはまた、クラスター管理者がクラスター作成に使用されたAWS IAMプリンシパルに自動的に付与されたcluster-admin権限を取り消したり調整したりすることも可能にします。

Cluster Access Management APIは次の2つの基本的な概念に依存しています：

- **アクセスエントリ（認証）**：Amazon EKSクラスターに認証を許可されたAWS IAMプリンシパル（ユーザーまたはロール）に直接リンクされたクラスターアイデンティティ。アクセスエントリはクラスターに紐づけられているため、クラスターが作成され、認証方法としてCluster Access Management APIを使用するように設定されていない限り、そのクラスターのアクセスエントリは存在しません。
- **アクセスポリシー（認可）**：アクセスエントリがAmazon EKSクラスターでアクションを実行することを許可するAmazon EKS固有のポリシー。アクセスポリシーはアカウントベースのリソースであり、クラスターがデプロイされていなくてもAWSアカウントに存在します。
  現在、Amazon EKSは事前定義された一部のAWS管理ポリシーのみをサポートしています。アクセスポリシーはIAMエンティティではなく、デフォルトのKubernetesクラスターロールに基づいてAmazon EKSによって定義および管理され、次のようにマッピングされます：

| アクセスポリシー            | RBAC            | 説明                                                                                                                       |
| --------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------- |
| AmazonEKSClusterAdminPolicy | `cluster-admin` | クラスターの管理者アクセスを付与                                                                                           |
| AmazonEKSAdminPolicy        | `admin`         | ほとんどのリソースへのアクセス権を付与、通常はNamespaceにスコープされる                                                    |
| AmazonEKSAdminViewPolicy    | `view`          | Secretを含むクラスター内のすべてのリソースをリスト/表示するアクセス権を付与（クラスター全体にスコープされたビューポリシー） |
| AmazonEKSEditPolicy         | `edit`          | ほとんどのKubernetesリソースを編集するアクセス権を付与、通常はNamespaceにスコープされる                                     |
| AmazonEKSViewPolicy         | `view`          | ほとんどのKubernetesリソースをリスト/表示するアクセス権を付与、通常はNamespaceにスコープされる                              |
| AmazonEMRJobPolicy          | N/A             | Amazon EKSクラスター上でAmazon EMRジョブを実行するためのカスタムアクセス                                                   |

アカウントで利用可能なアクセスポリシーのリストを確認するには、次のコマンドを実行します：

```bash
$ aws eks list-access-policies

{
    "accessPolicies": [
        {
            "name": "AmazonEKSAdminPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        },
        {
            "name": "AmazonEKSAdminViewPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
        },
        {
            "name": "AmazonEKSClusterAdminPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        },
        {
            "name": "AmazonEKSEditPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        },
        {
            "name": "AmazonEKSViewPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        },
        {
            "name": "AmazonEMRJobPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEMRJobPolicy"
        }
    ]
}
```

前述したように、Cluster Access Management APIは、APIサーバーリクエストに関するKubernetes認可決定において、アクセスポリシーによる許可とパスをサポートする上流のRBACとの組み合わせを可能にします（拒否はできません）。拒否決定は、上流のRBACとAmazon EKS認可者の両方がリクエスト評価の結果を判断できない場合に発生します。

以下の図は、Cluster Access Management APIがAWS IAMプリンシパルにAmazon EKSクラスターへの認証と認可を提供するために従うワークフローを示しています。

![CAM Auth Workflow](/docs/security/cluster-access-management/cam-workflow.webp)
