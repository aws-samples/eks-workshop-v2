---
title: "IRSAの適用"
sidebar_position: 24
hide_table_of_contents: true
tmdTranslationSourceHash: 'a0164f3962421ad66814dd318bcaae38'
---

クラスターでIAM roles for service accountsを使用するには、`IAM OIDC Identity Provider`を作成してクラスターに関連付ける必要があります。OIDCはすでにプロビジョニングされ、EKSクラスターに関連付けられています：

```bash
$ aws iam list-open-id-connect-providers
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
        }
    ]
}
```

Amazon EKSクラスターとの関連付けを確認します。

```bash
$ aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query 'cluster.identity'
{
    "oidc": {
        "issuer": "https://oidc.eks.us-west-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
    }
}
```

`carts`サービスがDynamoDBテーブルの読み書きに必要な権限を提供するIAM roleはすでに作成されています。以下のようにポリシーを確認できます：

```bash
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts",
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/*"
      ],
      "Sid": "AllAPIActionsOnCart"
    }
  ],
  "Version": "2012-10-17"
}
```

また、このroleには適切な信頼関係が設定されており、EKSクラスターに関連付けられたOIDCプロバイダーが、サブジェクトがcartsコンポーネントのServiceAccountである場合に限り、このroleを引き受けることができるようになっています。以下のように確認できます：

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/22E1209C76AE64F8F612F8E703E5BBD7"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/22E1209C76AE64F8F612F8E703E5BBD7:sub": "system:serviceaccount:carts:carts"
        }
      }
    }
  ]
}
```

あとは、`carts`アプリケーションに関連付けられているServiceAccountオブジェクトに必要なアノテーションを追加して再設定するだけです。これにより、IRSAが上記のIAM roleを使用するPodに正しい認可を提供できるようになります。
まず、`carts` Deploymentに関連付けられているSAを確認しましょう。

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

次に、Service Accountのアノテーション用のIAM roleのARNを提供する`CARTS_IAM_ROLE`の値を確認します。

```bash
$ echo $CARTS_IAM_ROLE
arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
```

使用するIAM roleを確認したら、Kustomizeを実行してServiceAccountに変更を適用できます。

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/irsa/service-account \
  | envsubst | kubectl apply -f-
```

これにより、ServiceAccountが次のように変更されます：

```kustomization
modules/security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

ServiceAccountにアノテーションが付与されたかを確認します。

```bash
$ kubectl describe sa carts -n carts | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
```

ServiceAccountを更新したので、cartsのPodを再作成して変更を反映させます：

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

