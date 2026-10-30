---
title: "AWS Secrets Manager にシークレットを保存する"
sidebar_position: 421
tmdTranslationSourceHash: '89fe2ca98f6ed6cf386c25c15672fc9c'
---

まず、AWS CLI を使用して AWS Secrets Manager にシークレットを作成しましょう。ユーザー名とパスワードの値を含む JSON エンコードされた認証情報を持つシークレットを作成します。

```bash
$ export SECRET_SUFFIX=$(openssl rand -hex 4)
$ export SECRET_NAME="$EKS_CLUSTER_AUTO_NAME-catalog-secret-${SECRET_SUFFIX}"
$ aws secretsmanager create-secret --name "$SECRET_NAME" \
  --secret-string '{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}' --region $AWS_REGION | jq
{
    "ARN": "arn:aws:secretsmanager:us-west-2:1234567890:secret:eks-workshop-catalog-secret-WDD8yS",
    "Name": "eks-workshop-catalog-secret-WDD8yS",
    "VersionId": "7e0b352d-6666-4444-aaaa-cec1f1d2df1b"
}
```

:::note
アカウント内の既存のシークレットと競合しないように、`openssl` を使用してシークレット名に一意のサフィックスを生成しています。
:::

シークレットが正常に作成されたことを、[AWS Secrets Manager Console](https://console.aws.amazon.com/secretsmanager/listsecrets) または AWS CLI のいずれかで確認できます。CLI を使用してシークレットのメタデータを確認してみましょう。

```bash
$ aws secretsmanager describe-secret --secret-id "$SECRET_NAME" | jq
{
    "ARN": "arn:aws:secretsmanager:us-west-2:1234567890:secret:eks-workshop-catalog-secret-WDD8yS",
    "Name": "eks-workshop-catalog-secret-WDD8yS",
    "LastChangedDate": "2023-10-10T20:44:51.882000+00:00",
    "VersionIdsToStages": {
        "94d1fe43-87f5-42fb-bf28-f6b090f0ca44": [
            "AWSCURRENT"
        ]
    },
    "CreatedDate": "2023-10-10T20:44:51.439000+00:00"
}
```

AWS Secrets Manager にシークレットを正常に作成できたので、次のセクションで Kubernetes アプリケーションで使用します。

