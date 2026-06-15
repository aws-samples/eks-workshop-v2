---
title: "DynamoDB アクセスの検証"
sidebar_position: 35
pagination_next: fastpaths/explore/index
tmdTranslationSourceHash: '71af52af1703fd93ecb5a1774ce76077'
---

これで、`carts` Service Account が認可された IAM ロールに関連付けられたため、`carts` Pod は DynamoDB テーブルへのアクセス許可を持つようになりました。もう一度ウェブストアにアクセスして、ショッピングカートに移動してください。

```bash
$ LB_HOSTNAME=$(kubectl get svc ui-nlb-auto -n ui -o yaml | yq .status.loadBalancer.ingress[0].hostname)
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlbaut-a9797f0f61.elb.us-west-2.amazonaws.com
```

`carts` Pod は DynamoDB サービスに到達でき、ショッピングカートにアクセスできるようになりました！

![Cart](/img/sample-app-screens/shopping-cart.webp)

AWS IAM ロールが Service Account に関連付けられると、その Service Account を使用して新しく作成される Pod は、[EKS Pod Identity webhook](https://github.com/aws/amazon-eks-pod-identity-webhook) によって傍受されます。この webhook は Amazon EKS クラスターのコントロールプレーンで実行され、AWS によって完全に管理されています。新しい `carts` Pod を詳しく見て、新しい環境変数を確認してください。

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

これらの環境変数について注目すべき点：

- `AWS_DEFAULT_REGION` - リージョンは自動的に EKS クラスターと同じに設定されます
- `AWS_STS_REGIONAL_ENDPOINTS` - リージョナル STS エンドポイントが設定され、`us-east-1` のグローバルエンドポイントへの負荷を避けます
- `AWS_CONTAINER_CREDENTIALS_FULL_URI` - この変数は、[HTTP 認証情報プロバイダー](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html)を使用して認証情報を取得する方法を AWS SDK に指示します。つまり、EKS Pod Identity は `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` ペアのような形式で認証情報を挿入する必要がなく、代わりに SDK は EKS Pod Identity メカニズムを介して一時的な認証情報を取得できます。この機能の詳細については、[AWS ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)をご覧ください。

アプリケーションで Pod Identity を正常に設定しました。

