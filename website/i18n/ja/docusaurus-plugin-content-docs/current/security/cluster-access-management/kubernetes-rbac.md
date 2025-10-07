---
title: "Kubernetes RBACとの統合"
sidebar_position: 14
kiteTranslationSourceHash: 0ac86d001c5ec50d2f31c060afddc908
---

前述したように、クラスターアクセス管理コントロールおよび関連APIは、Amazon EKSの既存のRBACオーソライザーを置き換えるものではありません。代わりに、Amazon EKSアクセスエントリはRBACオーソライザーと組み合わせて使用することで、AWS IAMプリンシパルにクラスターアクセスを付与しながら、Kubernetes RBACに依存して目的の権限を適用することができます。

この実習のセクションでは、Kubernetesグループを使用して詳細な権限を持つアクセスエントリを設定する方法を示します。これは、事前定義されたアクセスポリシーが過度に許容的である場合に役立ちます。実習の設定の一部として、`eks-workshop-carts-team`というIAMロールを作成しました。このシナリオでは、**carts**サービスのみを扱うチームに、`carts`名前空間内のすべてのリソースを表示する権限と、ポッドを削除する権限を提供する方法を示します。

まず、必要な権限をモデル化するKubernetesオブジェクトを作成しましょう。このRoleは、上記で概説した権限を提供します：

::yaml{file="manifests/modules/security/cam/rbac/role.yaml" paths="metadata.namespace,rules.0,rules.1"}

1. Role権限を`carts`名前空間にのみ制限します
2. このルールは読み取り専用操作 `verbs: ["get", "list", "watch"]` をすべてのリソース `resources: ["*"]` に許可します
3. このルールは削除操作 `verbs: ["delete"]` をポッドのみ `resources: ["pods"]` に対して許可します

そしてこの`RoleBinding`は、Roleを`carts-team`という名前のグループにマッピングします：

::yaml{file="manifests/modules/security/cam/rbac/rolebinding.yaml" paths="roleRef,subjects.0"}

1. `roleRef`は先ほど作成した`carts-team-role` Roleを参照します
2. `subjects`は、`carts-team`という名前のグループがRoleに関連付けられた権限を取得することを指定します

これらのマニフェストを適用しましょう：

```bash
$ kubectl --context default apply -k ~/environment/eks-workshop/modules/security/cam/rbac
```

次に、カートチームのIAMロールを`carts-team` Kubernetes RBACグループにマッピングするアクセスエントリを作成します：

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $CARTS_TEAM_IAM_ROLE \
  --kubernetes-groups carts-team
```

これで、このロールが持つアクセス権をテストできます。カートチームのIAMロールを使用してコンテキスト`carts-team`でクラスターに認証する新しい`kubeconfig`エントリをセットアップしましょう：

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $CARTS_TEAM_IAM_ROLE --alias carts-team --user-alias carts-team
```

それでは、カートチームのIAMロールを使用して`--context carts-team`を指定し、`carts`名前空間内のポッドにアクセスしてみましょう：

```bash
$ kubectl --context carts-team get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-hp7x8          1/1     Running   0          3m27s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

また、名前空間内のポッドを削除することもできるはずです：

```bash
$ kubectl --context carts-team delete pod --all -n carts
pod "carts-6d4478747c-hp7x8" deleted
pod "carts-dynamodb-d9f9f48b-k5v99" deleted
```

しかし、`Deployment`のような他のリソースを削除しようとすると、禁止されます：

```bash expectError=true
$ kubectl --context carts-team delete deployment --all -n carts
Error from server (Forbidden): deployments.apps is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "deployments" in API group "apps" in the namespace "carts"
```

また、別の名前空間のポッドにアクセスしようとしても、禁止されます：

```bash expectError=true
$ kubectl --context carts-team get pod -n catalog
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "pods" in API group "" in the namespace "catalog"
```

これにより、Kubernetes RBACグループをアクセスエントリに関連付けて、IAMロールにEKSクラスターへの細かな権限を提供する方法を示しました。
