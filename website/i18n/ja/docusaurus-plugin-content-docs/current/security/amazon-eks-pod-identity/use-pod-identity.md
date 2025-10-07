---
title: "EKS Podアイデンティティの使用"
sidebar_position: 34
hide_table_of_contents: true
kiteTranslationSourceHash: cd634a113e19b4c86057e0ea79176751
---

クラスターでEKS Podアイデンティティを使用するには、`EKS Pod Identity Agent`アドオンをEKSクラスターにインストールする必要があります。次のコマンドを使用してインストールしましょう：

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
{
    "addon": {
        "addonName": "eks-pod-identity-agent",
        "clusterName": "eks-workshop",
        "status": "CREATING",
        "addonVersion": "v1.1.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-west-2:1234567890:addon/eks-workshop/eks-pod-identity-agent/9ec6cfbd-8c9f-7ff4-fd26-640dda75bcea",
        "createdAt": "2024-01-12T22:41:01.414000+00:00",
        "modifiedAt": "2024-01-12T22:41:01.434000+00:00",
        "tags": {}
    }
}

$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
```

では、新しいアドオンによってEKSクラスターに作成されたものを見てみましょう。`kube-system`名前空間にデプロイされたDaemonSetがあり、クラスター内の各ノードでPodを実行しています。

```bash
$ kubectl -n kube-system get daemonset eks-pod-identity-agent
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
eks-pod-identity-agent    3         3         3       3            3           <none>          3d21h
$ kubectl -n kube-system get pods -l app.kubernetes.io/name=eks-pod-identity-agent
NAME                           READY   STATUS    RESTARTS   AGE
eks-pod-identity-agent-4tn28   1/1     Running   0          3d21h
eks-pod-identity-agent-hslc5   1/1     Running   0          3d21h
eks-pod-identity-agent-thvf5   1/1     Running   0          3d21h
```

`carts`サービスがDynamoDBテーブルの読み書きに必要な権限を提供するIAMロールは、このモジュールの最初のステップで`prepare-environment`スクリプトを実行したときに作成されました。次のように、ポリシーを表示できます：

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

ロールには、PodアイデンティティのためにEKSサービスプリンシパルがこのロールを引き受けることを許可する適切な信頼関係も設定されています。以下のコマンドで確認できます：

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
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

次に、Amazon EKS Podアイデンティティ機能を使用して、AWSのIAMロールをデプロイメントで使用するKubernetesサービスアカウントに関連付けます。関連付けを作成するには、次のコマンドを実行します：

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
{
    "association": {
        "clusterName": "eks-workshop",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo",
        "associationArn": "arn:aws::1234567890:podidentityassociation/eks-workshop/a-abcdefghijklmnop1",
        "associationId": "a-abcdefghijklmnop1",
        "tags": {},
        "createdAt": "2024-01-09T16:16:38.163000+00:00",
        "modifiedAt": "2024-01-09T16:16:38.163000+00:00"
    }
}
```

あとは`carts`デプロイメントが`carts`サービスアカウントを使用していることを確認するだけです：

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

サービスアカウントを確認したら、`carts`ポッドを再起動しましょう：

```bash hook=enable-pod-identity hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

これで、次のセクションで`carts`アプリケーションのDynamoDBアクセス権限の問題が解決されたかどうかを確認しましょう。
