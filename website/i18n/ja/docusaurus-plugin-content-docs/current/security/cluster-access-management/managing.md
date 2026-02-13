---
title: "クラスターアクセスの管理"
sidebar_position: 12
tmdTranslationSourceHash: 47ef58479d59d40fc0b2c0f1c8e64c12
---

Cluster Access Management APIの基本を理解したところで、実践的な活動を始めましょう。まず最初に、Cluster Access Management APIが利用可能になる前は、Amazon EKSは`aws-auth` ConfigMapを使用してクラスターへの認証とアクセス提供を行っていたことを知っておくことが重要です。Amazon EKSは現在、3つの異なる認証モードを提供しています：

1. `CONFIG_MAP`：`aws-auth` ConfigMapのみを使用（これは将来的に非推奨になります）
2. `API_AND_CONFIG_MAP`：EKSアクセスエントリAPIと`aws-auth` ConfigMapの両方から認証されたIAMプリンシパルを取得し、アクセスエントリを優先します
3. `API`：EKSアクセスエントリAPIのみに依存（推奨される方法）

:::note
クラスター設定を`CONFIG_MAP`から`API_AND_CONFIG_MAP`へ、そして`API_AND_CONFIG_MAP`から`API`へ更新することはできますが、その逆はできません。これは一方向の操作です - Cluster Access Management APIの使用に移行すると、`aws-auth` ConfigMap認証のみに戻ることはできなくなります。
:::

`awscli`を使用して、クラスターがどの認証方法で構成されているかを確認してみましょう：

```bash
$ aws eks describe-cluster --name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
{
  "authenticationMode": "API_AND_CONFIG_MAP"
}
```

クラスターがすでに認証オプションの1つとしてAPIを使用しているため、EKSはすでにいくつかのデフォルトのアクセスエントリをクラスターにマッピングしています。確認してみましょう：

```bash
$ aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
{
    "accessEntries": [
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-TesterCodeBuildRoleC9232875-RyhCKIXckZri"
    ]
}
```

これらのアクセスエントリは、認証モードが`API_AND_CONFIG_MAP`または`API`に設定されている場合に、クラスター作成者エンティティとクラスターに属するマネージドノードグループへのアクセスを許可するために自動的に作成されます。

クラスター作成者は、AWS Console、`awscli`、eksctlまたはAWS CloudFormationやTerraformなどのInfrastructure-as-Code（IaC）ツールを通じて実際にクラスターを作成したエンティティです。このアイデンティティは作成時に自動的にクラスターにマッピングされ、認証方法が`CONFIG_MAP`に制限されていた過去には見えませんでした。現在、Cluster Access Management APIを使用すると、このアイデンティティマッピングの作成をオプトアウトしたり、クラスターがデプロイされた後に削除したりすることが可能です。

これらのアクセスエントリについて詳しい情報を見てみましょう：

```bash
$ NODE_ROLE=$(aws eks list-access-entries --cluster $EKS_CLUSTER_NAME --output text | awk '/NodeInstanceRole/ {print $2}')
$ aws eks describe-access-entry --cluster $EKS_CLUSTER_NAME --principal-arn $NODE_ROLE
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "kubernetesGroups": [
            "system:nodes"
        ],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr/dcc7957b-b333-5c6b-f487-f7538085d799",
        "createdAt": "2024-04-29T17:46:47.836000+00:00",
        "modifiedAt": "2024-04-29T17:46:47.836000+00:00",
        "tags": {},
        "username": "system:node:{{EC2PrivateDNSName}}",
        "type": "EC2_LINUX"
    }
}
```
