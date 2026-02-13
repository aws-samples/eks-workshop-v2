---
title: "DynamoDBアクセスの検証"
sidebar_position: 35
tmdTranslationSourceHash: 4130a6ea94698da1a24cf632242194ac
---

これで、`carts` ServiceAccountが認可されたIAMロールに関連付けられたため、`carts` PodはDynamoDBテーブルにアクセスする権限を持ちました。再度Webストアにアクセスし、ショッピングカートに移動しましょう。

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

`carts` PodはDynamoDBサービスに到達でき、ショッピングカートが利用可能になりました！

![カート](/img/sample-app-screens/shopping-cart.webp)

AWS IAMロールがServiceAccountに関連付けられた後、そのServiceAccountを使用して新しく作成されたPodは、[EKS Pod Identityウェブフック](https://github.com/aws/amazon-eks-pod-identity-webhook)によって傍受されます。このウェブフックはAmazon EKSクラスターのコントロールプレーン上で実行され、AWSによって完全に管理されています。新しい`carts` Podを詳しく調べて、新しい環境変数を確認しましょう：

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

これらの環境変数に関する注目すべき点：

- `AWS_DEFAULT_REGION` - リージョンは自動的にEKSクラスターと同じリージョンに設定されます
- `AWS_STS_REGIONAL_ENDPOINTS` - リージョナルSTSエンドポイントが設定され、`us-east-1`のグローバルエンドポイントに過度の負荷をかけないようにしています
- `AWS_CONTAINER_CREDENTIALS_FULL_URI` - この変数は、AWS SDKに[HTTPクレデンシャルプロバイダー](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html)を使用してクレデンシャルを取得する方法を伝えます。これにより、EKS Pod Identityは`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`のようなペアを介してクレデンシャルを注入する必要がなく、代わりにSDKはEKS Pod Identityメカニズムを介して一時的なクレデンシャルを取得できます。この仕組みの詳細については、[AWS公式ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)で詳しく説明されています。

これでアプリケーションでPod Identityを正常に設定できました。
