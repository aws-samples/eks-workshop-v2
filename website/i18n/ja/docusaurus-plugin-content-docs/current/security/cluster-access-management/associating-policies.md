---
title: "アクセスポリシーの関連付け"
sidebar_position: 13
tmdTranslationSourceHash: ba70c54bd69ec0917ba9964b493675fa
---

`STANDARD`タイプのアクセスエントリに対して、1つまたは複数のアクセスポリシーを割り当てることができます。Amazon EKSは、他のタイプのアクセスエントリに対して、クラスター内で正常に機能するために必要な権限を自動的に付与します。Amazon EKSアクセスポリシーには、IAM権限ではなく、Kubernetes権限が含まれています。アクセスポリシーをアクセスエントリに関連付ける前に、各アクセスポリシーに含まれるKubernetes権限を十分に理解しておいてください。

ラボセットアップの一環として、`eks-workshop-read-only`という名前のIAMロールを作成しました。このセクションでは、読み取り専用アクセスのみを許可する権限セットを持つEKSクラスターへのアクセスをこのロールに提供します。

まず、このIAMロールのアクセスエントリを作成しましょう：

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE
```

次に、`AmazonEKSViewPolicy`ポリシーを使用してこのプリンシパルのアクセスポリシーを関連付けることができます：

```bash wait=30
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=cluster
```

`--access-scope`の値に`type=cluster`を使用していることに注目してください。これにより、プリンシパルはクラスター全体に対する読み取り専用アクセスが与えられます。

次に、このロールが持つアクセス権をテストできます。まず、読み取り専用IAMロールを使用してクラスターで認証する新しい`kubeconfig`エントリを設定します。これは`readonly`という名前の別の`kubectl`コンテキストにマッピングされます。この仕組みについては、[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)で詳細を確認できます。

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly --user-alias readonly
```

これで引数`--context readonly`を使って`kubectl`コマンドを実行し、読み取り専用IAMロールで認証できます。`kubectl auth whoami`を使用してこれを確認し、正しいロールを偽装していることを確認しましょう：

```bash
$ kubectl --context readonly auth whoami
ATTRIBUTE             VALUE
Username              arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth
UID                   aws-iam-authenticator:1234567890:AKIAIOSFODNN7EXAMPLE
Groups                [system:authenticated]
Extra: accessKeyId    [AKIAIOSFODNN7EXAMPLE]
Extra: arn            [arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth]
Extra: canonicalArn   [arn:aws:iam::1234567890:role/eks-workshop-read-only]
Extra: principalId    [AKIAIOSFODNN7EXAMPLE]
Extra: sessionName    [EKSGetTokenAuth]
```

次に、このIAMロールを使用してクラスター内のポッドにアクセスしてみましょう：

```bash
$ kubectl --context readonly get pod -A
```

これによりクラスター内のすべてのポッドが返されるはずです。ただし、読み取り以外のアクションを実行しようとすると、エラーが発生するはずです：

```bash expectError=true
$ kubectl --context readonly delete pod -n ui --all
Error from server (Forbidden): pods "ui-7c7948bfc8-wbsbr" is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot delete resource "pods" in API group "" in the namespace "ui"
```

次に、ポリシーを1つ以上の名前空間に制限する方法を調査しましょう。`--access-scope type=namespace`を使用して読み取り専用IAMロールのアクセスポリシーの関連付けを更新しましょう：

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=namespace,namespaces=carts
```

この関連付けは明示的に`carts`名前空間へのアクセスのみを許可し、以前のクラスター全体の関連付けを置き換えます。テストしてみましょう：

```bash
$ kubectl --context readonly get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

しかし、すべての名前空間からポッドを取得しようとすると、禁止されます：

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

`readonly`ロールの関連付けを一覧表示してみましょう：

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:02:22.566000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

先述したように、同じ`AmazonEKSViewPolicy`ポリシーARNを使用したため、以前のクラスタースコープのアクセス設定を名前空間スコープのものに置き換えました。では、`ui`名前空間にスコープされた別のポリシーARNを関連付けてみましょう：

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=ui
```

前回アクセス拒否されたコマンドを実行して、`ui`名前空間のPodを削除してみましょう：

```bash
$ kubectl --context readonly delete pod -n ui --all
pod "ui-7c7948bfc8-xdmnv" deleted
```

これで両方の名前空間へのアクセス権が得られました。関連付けられたアクセスポリシーを一覧表示してみましょう：

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "ui"
                ]
            },
            "associatedAt": "2024-05-29T17:23:55.299000+00:00",
            "modifiedAt": "2024-05-29T17:23:55.299000+00:00"
        },
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:23:28.168000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

ご覧の通り、異なるレベルのアクセス権を提供するために複数のアクセスポリシーを関連付けることが可能です。

クラスター内のすべてのPodを一覧表示しようとするとどうなるか確認してみましょう：

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

アクセススコープが`ui`と`carts`名前空間のみにマッピングされているため、クラスター全体へのアクセス権はまだありません。これは予想通りの結果です。

これにより、事前定義されたEKSアクセスポリシーをアクセスエントリに関連付けて、IAMロールにEKSクラスターへのアクセス権を簡単に提供する方法を示しました。
