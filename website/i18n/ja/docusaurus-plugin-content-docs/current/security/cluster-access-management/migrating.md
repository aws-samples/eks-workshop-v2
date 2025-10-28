---
title: "aws-auth アイデンティティマッピングからの移行"
sidebar_position: 20
kiteTranslationSourceHash: '27e2f94a480c0774ad93f80a8b436f68'
---

Amazon EKS を既に使用しているお客様は、クラスターへの IAM プリンシパルアクセスを管理するための `aws-auth` ConfigMap メカニズムに慣れているかもしれません。このセクションでは、この古いメカニズムからクラスターアクセスエントリを使用する方法への移行方法を示します。

IAM ロール `eks-workshop-admins` は、EKS 管理者権限を持つグループに使用される EKS クラスターに事前設定されています。`aws-auth` ConfigMap を確認してみましょう：

```bash
$ kubectl --context default get -n kube-system cm aws-auth -o yaml
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::1234567890:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-acgt4WAVfXAA
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::1234567890:role/eks-workshop-admins
      username: cluster-admin
  mapUsers: |
    []
kind: ConfigMap
metadata:
  creationTimestamp: "2024-05-09T15:21:57Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "5186190"
  uid: 2a1f9dc7-e32d-44e5-93b3-e5cf7790d95e
```

この IAM ロールになりすましてアクセス権を確認しましょう：

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $ADMINS_IAM_ROLE --alias admins --user-alias admins
```

どのポッドでも一覧表示できるはずです。例えば：

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

次に、この IAM ロールの `aws-auth` ConfigMap エントリを削除しましょう。便宜上 `eksctl` を使用します：

```bash wait=10
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME --arn $ADMINS_IAM_ROLE
```

先ほどと同じコマンドを試すと、今度はアクセスが拒否されます：

```bash expectError=true
$ kubectl --context admins get pod -n carts
error: You must be logged in to the server (Unauthorized)
```

クラスター管理者がクラスターに再度アクセスできるようにアクセスエントリを追加しましょう：

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE
```

次に、`AmazonEKSClusterAdminPolicy` ポリシーを使用して、このプリンシパルのアクセスポリシーを関連付けます：

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

これでアクセスが再び機能していることをテストできます：

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

これらの手順に従うことで、IAM ロールを `aws-auth` ConfigMap から、Amazon EKS クラスターへのアクセスをより合理的に管理する新しいクラスターアクセス管理 API の使用に正常に移行しました。

