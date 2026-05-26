---
title: "EKS Pod Identityの使用"
sidebar_position: 34
hide_table_of_contents: true
tmdTranslationSourceHash: 'c2ccba1ccd0c6f8192e1325cbaff51bc'
---

Amazon EKS Auto Modeでは、EKS Pod Identity Agentがすでに含まれており、AWSによってコントロールプレーンで管理されています。既存のPod Identityアソシエーションを確認することで、Pod Identityが利用可能であることを確認できます：

```bash
$ aws eks list-pod-identity-associations --cluster-name $EKS_CLUSTER_AUTO_NAME --namespace carts
{
    "associations": []
}
```

`carts`サービスがDynamoDBテーブルへの読み書きに必要な権限を提供するIAM roleは、Auto Modeクラスターのセットアップ時に作成されました。以下のようにポリシーを表示できます：

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

また、このroleには適切な信頼関係が設定されており、EKS Service PrincipalがPod Identityのためにこのroleをassumeできるようになっています。以下のコマンドで確認できます：

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

次に、Amazon EKS Pod Identity機能を使用して、Deploymentによって使用されるKubernetes Service AccountとAWS IAM roleを関連付けます。アソシエーションを作成するには、以下のコマンドを実行します：

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

残りは、`carts` Deploymentが`carts` Service Accountを使用していることを確認することです：

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

Service Accountが確認できたので、`carts` Podをリサイクルしましょう：

```bash hook=enable-pod-identity hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
```

Podのステータスを確認して、正常にロールアウトされたかを確認しましょう：

```bash timeout=360
$ kubectl -n carts rollout status deployment/carts --timeout=300s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

それでは、次のセクションで、cartsアプリケーションで発生していたDynamoDB権限の問題が解決されたかどうかを確認しましょう。

