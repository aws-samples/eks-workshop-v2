---
title: "DynamoDB アクセスの検証"
sidebar_position: 35
tmdTranslationSourceHash: 8c2ac2956c8fb49e1b1d9d6e9b884b1b
---

これで、`carts` Service Account が認可された IAM ロールに関連付けられたため、`carts` Pod は DynamoDB テーブルにアクセスする権限を持つようになりました。ウェブストアに再度アクセスし、ショッピングカートに移動してください。

```bash
$ ALB_HOSTNAME=$(kubectl get ingress ui-auto -n ui -o yaml | yq .status.loadBalancer.ingress[0].hostname)
$ echo "http://$ALB_HOSTNAME"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

`carts` Pod は DynamoDB サービスに到達でき、ショッピングカートにアクセスできるようになりました！

![Cart](/img/sample-app-screens/shopping-cart.webp)

:::caution
アプリケーションの読み込み時にエラーが表示される場合は、[前のセクション](./use-pod-identity.md)の最後で `carts` Pod を再起動したことを確認してください。
:::

AWS IAM ロールが Service Account に関連付けられた後、その Service Account を使用して新しく作成された Pod は、[EKS Pod Identity webhook](https://github.com/aws/amazon-eks-pod-identity-webhook) によってインターセプトされます。この webhook は Amazon EKS クラスターの control plane で実行され、AWS によって完全に管理されています。新しい `carts` Pod を詳しく見て、新しい環境変数を確認しましょう:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

これらの環境変数について注目すべき点:

- `AWS_DEFAULT_REGION` - リージョンは EKS クラスターと同じものに自動的に設定されます
- `AWS_STS_REGIONAL_ENDPOINTS` - `us-east-1` のグローバルエンドポイントに過度の負荷をかけないように、リージョナル STS エンドポイントが設定されます
- `AWS_CONTAINER_CREDENTIALS_FULL_URI` - この変数は、[HTTP credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html) を使用して認証情報を取得する方法を AWS SDK に伝えます。つまり、EKS Pod Identity は `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` ペアのような認証情報を注入する必要がなく、代わりに SDK は EKS Pod Identity メカニズムを介して一時的な認証情報を取得できます。この機能の詳細については、[AWS ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)をご覧ください。

アプリケーションで Pod Identity の設定が正常に完了しました。

