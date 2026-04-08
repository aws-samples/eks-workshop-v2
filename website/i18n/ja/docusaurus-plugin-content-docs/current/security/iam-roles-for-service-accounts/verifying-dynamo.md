---
title: "DynamoDBのアクセス検証"
sidebar_position: 25
tmdTranslationSourceHash: 90eb06acc2de6b787b58060553698681
---

今、`carts` サービスアカウントが承認されたIAMロールで注釈付けされたので、`carts` Podは DynamoDBテーブルにアクセスする権限を持っています。Web ストアに再度アクセスして、ショッピングカートに移動してみましょう。

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

`carts` PodはDynamoDBサービスにアクセスできるようになり、ショッピングカートが利用可能になりました！

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart">
<img src={require('@site/static/img/sample-app-screens/shopping-cart.webp').default}/>
</Browser>

新しい`carts` Podをより詳しく見て、何が起きているかを確認しましょう。

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_ROLE_ARN=arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

これらの環境変数はConfigMapのようなものや、デプロイメントに直接設定されたものではありません。代わりに、これらはIRSAによって自動的に設定され、AWSのSDKがAWS STSサービスから一時的な認証情報を取得できるようになっています。

注目すべき点は以下の通りです：

- リージョンはEKSクラスターと同じものに自動的に設定されています
- STSリージョナルエンドポイントが設定され、`us-east-1`のグローバルエンドポイントに過度の負荷をかけることを避けています
- ロールARNは、以前にKubernetesのServiceAccountに注釈として使用したロールと一致しています

最後に、`AWS_WEB_IDENTITY_TOKEN_FILE`変数は、WebID連携を使用して認証情報を取得する方法をAWS SDKに伝えています。これにより、IRSAは`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`ペアのような認証情報を注入する必要がなく、代わりにSDKはOIDCメカニズムを通じて一時的な認証情報を提供されます。この仕組みについての詳細は、[AWSドキュメント](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html)で確認できます。
