---
title: "Pod IAMの理解"
sidebar_position: 23
kiteTranslationSourceHash: 8fc870acc614f97786463eea6ee471a4
---

問題を探るまず最初の場所は、`carts`サービスのログです：

```bash hook=pod-logs
$ LATEST_POD=$(kubectl get pods -n carts --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
$ kubectl logs -n carts -p $LATEST_POD
[...]
***************************
アプリケーションの起動に失敗しました
***************************

説明：

Amazon DynamoDBにアクセスする際にエラーが発生しました：

User: arn:aws:sts::1234567890:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-rjjGEigUX8KZ/i-01f378b057326852a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: PUIFHHTQ7SNQVERCRJ6VHT8MBBVV4KQNSO5AEMVJF66Q9ASUAAJG)

アクション：

DynamoDBテーブルが作成されていること、およびIAM認証情報が適切なアクセス権で設定されていることを確認してください。
```

アプリケーションはエラーを生成しており、DynamoDBにアクセスするためにPodが使用しているIAMロールに必要な権限がないことを示しています。これは、Podに関連付けられたIAMロールやポリシーがない場合、デフォルトでそのPodが実行されているEC2インスタンスに割り当てられているインスタンスプロファイルにリンクされたIAMロールを使用するためです。この場合、このロールにはDynamoDBへのアクセスを許可するIAMポリシーがありません。

解決策の一つとして、EC2インスタンスプロファイルのIAM権限を拡張することが考えられますが、これによりそのインスタンス上で実行されるすべてのPodがDynamoDBテーブルにアクセスできるようになります。これは最小権限の原則に違反し、セキュリティのベストプラクティスではありません。代わりに、EKS Pod Identityを使用して、`carts`アプリケーションに必要な特定の権限をPodレベルで提供し、きめ細かいアクセス制御を確保します。
