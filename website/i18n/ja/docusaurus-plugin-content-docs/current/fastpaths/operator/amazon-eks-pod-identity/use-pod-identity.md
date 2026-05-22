---
title: "EKS Pod Identity の使用"
sidebar_position: 34
hide_table_of_contents: true
tmdTranslationSourceHash: '2b0a7dd5bfdf5b8f031c0ed19f8e3f74'
---

Amazon EKS Auto Mode では、EKS Pod Identity Agent がすでに含まれており、AWS によってコントロールプレーンで管理されています。既存の Pod Identity アソシエーションを確認することで、Pod Identity が利用可能であることを確認できます。

```bash
$ aws eks list-pod-identity-associations --cluster-name $EKS_CLUSTER_AUTO_NAME --namespace carts
{
    "associations": []
}
```

`carts` サービスが DynamoDB テーブルに読み書きするために必要な権限を提供する IAM role が、Auto Mode クラスターのセットアップ時に作成されています。以下のようにポリシーを表示できます。

```bash
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo | jq .
{
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:us-west-2:267912352941:table/eks-workshop-auto-carts",
        "arn:aws:dynamodb:us-west-2:267912352941:table/eks-workshop-auto-carts/index/*"
      ],
      "Sid": "AllAPIActionsOnCart"
    }
  ],
  "Version": "2012-10-17"
}
```

この role には、EKS サービスプリンシパルが Pod Identity のためにこの role を引き受けることを許可する、適切な信頼関係も設定されています。以下のコマンドで表示できます。

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_AUTO_NAME}-carts-dynamo | jq .
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
```

次に、Amazon EKS Pod Identity 機能を使用して、デプロイメントで使用される Kubernetes Service Account に AWS IAM role を関連付けます。アソシエーションを作成するには、以下のコマンドを実行します。

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts --service-account carts | jq .
{
    "association": {
        "clusterName": "eks-workshop-auto",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::267912352941:role/eks-workshop-auto-carts-dynamo",
        "associationArn": "arn:aws:eks:us-west-2:267912352941:podidentityassociation/eks-workshop-auto/a-yg5uoymvtfgdg5tcj",
        "associationId": "a-yg5uoymvtfgdg5tcj",
        "tags": {},
        "createdAt": "2025-10-11T01:13:27.763000+00:00",
        "modifiedAt": "2025-10-11T01:13:27.763000+00:00",
        "disableSessionTags": false
    }
}
```

残りの作業は、`carts` Deployment が `carts` Service Account を使用していることを確認することです。

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

Service Account が確認できたので、`carts` Pod をリサイクルしましょう。

```bash hook=enable-pod-identity hookTimeout=430 timeout=360
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts --timeout=300s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

それでは、次のセクションで、carts アプリケーションで発生していた DynamoDB の権限の問題が解決されたかどうかを確認しましょう。

