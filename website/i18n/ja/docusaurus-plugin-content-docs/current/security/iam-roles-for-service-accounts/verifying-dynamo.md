---
title: "DynamoDBのアクセス検証"
sidebar_position: 25
tmdTranslationSourceHash: a2a73fcfdbdf061a0e27089000ce5e6a
---

`carts` Service Accountに承認されたIAMロールが注釈として設定されたことで、`carts` PodはDynamoDBテーブルにアクセスする権限を持つようになりました。次のコマンドで取得したURLから、Webストアのショッピングカートページを開いてください。

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/cart"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart
```

`carts` PodはDynamoDBサービスにアクセスできるようになり、ショッピングカートが利用可能になりました！

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart">
<img src={require('@site/static/img/sample-app-screens/shopping-cart.webp').default}/>
</Browser>

新しい `carts` Podをより詳しく見て、何が起きているかを確認しましょう。

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_ROLE_ARN=arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

これらの環境変数は、ConfigMapのようなものを使って渡されたり、Deploymentに直接設定されたりしたものではありません。代わりに、IRSAによって自動的に設定されたものであり、AWS SDKがAWS STSサービスから一時的な認証情報を取得できるようにしています。

注目すべき点は以下の通りです。

- リージョンはEKSクラスターと同じものに自動的に設定されています
- STSリージョナルエンドポイントが設定されており、`us-east-1` のグローバルエンドポイントに過度な負荷をかけることを避けています
- ロールARNは、先ほどKubernetesのServiceAccountに注釈として設定したロールと一致しています

最後に、`AWS_WEB_IDENTITY_TOKEN_FILE` 変数は、ウェブIDフェデレーションを使用して認証情報を取得する方法をAWS SDKに伝えています。これにより、IRSAは `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` のペアのような認証情報を注入する必要がなくなり、代わりにSDKはOIDCメカニズムを通じて一時的な認証情報を受け取ることができます。この仕組みの詳細については、[AWSドキュメント](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html)を参照してください。
