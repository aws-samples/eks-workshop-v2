---
title: "Pod IAMの理解"
sidebar_position: 23
tmdTranslationSourceHash: 921036b29d3f3d09674d38d5fde46585
---

この問題の調査で最初に見るべき場所は、`carts`サービスのログです：

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

アプリケーションはDynamoDBにアクセスするために使用しているIAMロールに必要な権限がないことを示すエラーを生成しています。これは、Podに紐付けられたIAMロールやポリシーがない場合、デフォルトでPodが実行されているEC2インスタンスに割り当てられたインスタンスプロファイルに関連付けられたIAMロールを使用するためです。この場合、そのロールにはDynamoDBへのアクセスを許可するIAMポリシーがありません。

この問題を解決する一つの方法は、EC2ワーカーノードのIAM権限を拡張することですが、これによりそのノード上で実行されるすべてのPodがDynamoDBテーブルにアクセスできるようになります。しかし、これはセキュリティのベストプラクティスを反映していません。代わりに、IAM Roles for Service Accounts（IRSA）を使用して、`carts`サービス内のPodに特定のアクセス権を付与します。
