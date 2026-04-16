---
title: "認証と認可"
sidebar_position: 50
tmdTranslationSourceHash: 7158d65ea5b747af19da43c993b3941f
---

**<i>認証</i>**タブをクリックして<i>ServiceAccounts</i>セクションに移動すると、名前空間ごとにKubernetesのサービスアカウントリソースを表示できます。

:::info
追加の例については[セキュリティ](../../../security/)モジュールをご確認ください。
:::
[ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)はPod内で実行されるプロセスにIDを提供します。Podを作成する際、サービスアカウントを指定しない場合、同じ名前空間内のデフォルトのサービスアカウントが自動的に割り当てられます。

![Insights](/img/resource-view/auth-resources.jpg)

特定の<i>サービスアカウント</i>の詳細を表示するには、名前空間まで移動し、表示したいサービスアカウントをクリックすると、<i>ラベル</i>、<i>アノテーション</i>、<i>イベント</i>などの追加情報が表示されます。以下は<i>catalog</i>サービスアカウントの詳細ビューです。

EKSでは、リクエストが<i>認可</i>（アクセス許可の付与）される前に、**<i>認証</i>**（ログイン）する必要があります。KubernetesはREST APIリクエストに共通する属性を期待します。つまり、EKSの認可はアクセス制御に[AWS Identity and Access Management](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html)と連携します。

このラボでは、Kubernetesの**ロールベースアクセス制御（RBAC）**リソース：ClusterRoles、Roles、ClusterRoleBindings、RoleBindingsを表示します。RBACは、EKSクラスターにマッピングされたIAMロールに従って、EKSクラスターとそのオブジェクトへの制限された最小特権アクセスを提供するプロセスです。以下の図は、ユーザーまたはサービスアカウントがKubernetesクライアントとAPIを介してEKSクラスター内のオブジェクトにアクセスしようとしたときに、アクセス制御がどのように流れるかを示しています。

:::info
追加の例については[セキュリティ](../../../security/)モジュールをご確認ください。
:::

![Insights](/img/resource-view/autz-index.jpg)

**[Role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)**はユーザーに適用される一連のアクセス許可を定義します。ロールベースアクセス制御（RBAC）は、組織内の個々のユーザーの役割に基づいてコンピュータやネットワークリソースへのアクセスを規制する方法です。Roleは常に特定の名前空間内でアクセス許可を設定し、Roleを作成する際には、それが属する名前空間を指定する必要があります。

**_リソースタイプ_** - ***認可***セクションでは、クラスターの***ClusterRoles***と***Roles***リソースを名前空間ごとに表示できます。

![Insights](/img/resource-view/autz-role.jpg)

***cluster-autoscaler-aws-cluster-autoscaler***ロールをクリックすると、そのロールの詳細が表示されます。以下のスクリーンショットは、名前空間***kube-system***に作成された***cluster-autoscaler-aws-cluster-autoscaler***ロールを示しており、***configmaps***リソースに対する***削除***、**_取得_**、***更新***の権限を持っています。

![Insights](/img/resource-view/autz-role-detail.jpg)

**[ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)**はクラスター全体にスコープされたルールのセットであり、名前空間ではないため、***Role***とは異なります。***ClusterRoles***は付加的であり、「拒否」ルールを設定することはできません。通常、クラスター全体の権限を定義するために***ClusterRoles***を使用します。

**[Role binding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)**はロールの権限をユーザーまたはユーザーのセットに付与します。Rolebindingsは作成時に特定の名前空間に割り当てられます。Rolebindingリソースは、サブジェクト（ユーザー、グループ、またはサービスアカウント）のリストと、付与されるロールへの参照を保持しています。***RoleBinding***はpods、replicasets、jobs、deploymentsなど、特定の名前空間内の権限を付与します。一方、***ClusterRoleBinding***はノードなどのクラスタースコープのリソースを付与します。

**[ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)**は***ClusterRoles***をユーザーのセットに接続します。これらはクラスターにスコープされ、***Roles***や***RoleBindings***のように名前空間にバインドされません。

![Insights](/img/resource-view/authz-crolebinding.jpg)
