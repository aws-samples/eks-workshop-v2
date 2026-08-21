---
title: "Argo CD による継続的デリバリー"
sidebar_position: 20
tmdTranslationSourceHash: 'e15e3a3e5494a68c2803046eb72a4b41'
---

::required-time

[ACK ラボ](../ack/)では、ACK capability を使用して Kubernetes から AWS リソースをプロビジョニングしました。このラボでは、アプリケーションがクラスターに_デリバリー_される方法を変更します。`kubectl apply` を手動で実行する代わりに、**Argo CD EKS capability** を使用して `catalog` サービスを Git リポジトリから継続的に reconcile させます。

Argo CD は[セルフマネージド Argo CD ラボ](/docs/automation/gitops/argocd)で示されているように、自分で実行することができます。そこでは `helm install argocd` を実行し、`argocd-server` LoadBalancer を待機し、初期管理者シークレットを取得します。その場合、そのコントロールプレーンの可用性、スケーリング、パッチ適用、アップグレードを所有することになります。このラボでは代わりに Argo CD EKS capability を使用します。コントロールプレーンは、クラスターの外部の AWS 管理インフラストラクチャで実行され、AWS がその運用を処理し、IAM Capability Role を引き受けて CodeCommit からプルし、クラスターにデプロイします。

:::tip セットアップ済みの内容

- **Argo CD EKS 管理 capability** が `ACTIVE` 状態で、サインイン用に **AWS IAM Identity Center** とフェデレーションされています(ローカルユーザーや管理者パスワードはありません)。
- **AWS CodeCommit リポジトリ**には `catalog` マニフェストが事前にシードされており、capability は IAM ロールを使用してそこからプルするため、SSH キーや Git 認証情報を管理する必要がありません。
- `git-remote-codecommit` は、リポジトリをクローンするために web IDE に事前インストールされています。

:::

このラボを通じて、以下を実施します:

1. Argo CD capability が `ACTIVE` 状態であり、Argo CD API リソースがクラスターに存在することを確認します。
2. クラスターを Argo CD デプロイメントターゲットとして登録し、シードされた CodeCommit リポジトリを指す `Application` を作成し、自動同期を有効にします。
3. CodeCommit にレプリカ数の変更をプッシュして GitOps 更新をトリガーし、Argo CD が自動的にロールアウトするのを確認します。

:::info
以下のすべてのステップは、Kubernetes API (`argoproj.io` リソースに対する `kubectl`)を通じて Argo CD を駆動するため、サインインなしでラボが機能します。Identity Center UI サインインは、ダッシュボードを探索したい場合のオプションのウォークスルーです。
:::

## capability の確認

capability が `ACTIVE` であることを確認します:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ARGOCD_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

capability は `CREATING → ACTIVE` を経由して遷移します。ステータスが `ACTIVE` 以外の場合は、しばらく待ってからコマンドを再実行してください。

次に、Argo CD Custom Resource Definitions (CRD) がクラスターに登録されていることを確認します:

```bash
$ kubectl api-resources --api-group=argoproj.io
NAME             SHORTNAMES   APIVERSION                       NAMESPACED   KIND
applications     app,apps     argoproj.io/v1alpha1             true         Application
applicationsets  appset,as    argoproj.io/v1alpha1             true         ApplicationSet
appprojects      appproj,...  argoproj.io/v1alpha1             true         AppProject
```

CRD は存在しますが、Argo CD コントロールプレーンは存在しません。ノード上で Argo CD が実行されていないことを確認します:

```bash
$ kubectl get pods -A | grep -i argocd || echo "No Argo CD pods in the cluster"
No Argo CD pods in the cluster
```

これが管理された capability の全体的なポイントです。セルフマネージド Argo CD ラボでは、argocd-server、repo-server、そして redis Pod を `helm install` し、それらのアップグレードとスケーリングを所有することになります。ここでは、そのコントロールプレーン全体がクラスター外の AWS 所有インフラストラクチャで実行されます。クラスター内に取得するのは CRD だけであり、これを使用して Application を宣言します。

