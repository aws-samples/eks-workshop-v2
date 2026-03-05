---
title: "Pod IAM の理解"
sidebar_position: 33
tmdTranslationSourceHash: '8fc870acc614f97786463eea6ee471a4'
---

問題を調査する最初の場所は、`carts` サービスのログです：

```bash hook=pod-logs
$ LATEST_POD=$(kubectl get pods -n carts --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
$ kubectl logs -n carts -p $LATEST_POD
[...]
***************************
APPLICATION FAILED TO START
***************************

Description:

An error occurred when accessing Amazon DynamoDB:

User: arn:aws:sts::1234567890:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-rjjGEigUX8KZ/i-01f378b057326852a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: PUIFHHTQ7SNQVERCRJ6VHT8MBBVV4KQNSO5AEMVJF66Q9ASUAAJG)

Action:

Check that the DynamoDB table has been created and your IAM credentials are configured with the appropriate access.
```

アプリケーションはエラーを生成しており、これは Pod が DynamoDB へのアクセスに使用している IAM role に必要な権限がないことを示しています。これは、デフォルトでは、IAM role やポリシーが Pod にリンクされていない場合、実行されている EC2 インスタンスプロファイルに割り当てられた IAM role を使用するために発生しています。この場合、この role には DynamoDB へのアクセスを許可する IAM ポリシーがありません。

1 つのアプローチとして、EC2 インスタンスプロファイルの IAM 権限を拡張することもできますが、これによりそれらのインスタンス上で実行されるすべての Pod が DynamoDB テーブルにアクセスできるようになります。これは最小権限の原則に違反し、セキュリティのベストプラクティスではありません。代わりに、EKS Pod Identity を使用して、`carts` アプリケーションが必要とする特定の権限を Pod レベルで提供し、きめ細かいアクセス制御を確保します。
