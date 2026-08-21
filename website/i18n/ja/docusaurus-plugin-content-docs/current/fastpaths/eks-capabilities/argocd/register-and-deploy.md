---
title: "GitOps で catalog を配信する"
sidebar_position: 30
tmdTranslationSourceHash: '4a011efb0f55c55a75b4aa989c492376'
---

**GitOps** とは、Git リポジトリがクラスター内で実行されるものの信頼できる情報源であることを意味します。手動で `kubectl apply` を実行する代わりに、マニフェストを Git にコミットし、コントローラーが継続的にクラスターを Git に一致するように調整します。Argo CD がそのコントローラーです。

ここでの Git リポジトリは、`prepare-environment` によって作成され、シードされた AWS CodeCommit リポジトリ `$EKS_CAP_CODECOMMIT_REPO` です。これには `catalog/` ディレクトリの下に `catalog` サービスの Kubernetes マニフェストが含まれています。

現在、`catalog` サービスはベースアプリケーションの一部として実行されており、`kubectl` で直接適用されています。これを Argo CD に所有権を移譲し、代わりにそのリポジトリから配信されるようにします。2つの宣言的なステップでそれが実現します。このクラスターをデプロイメントターゲットとして登録し、次にリポジトリを指す Argo CD `Application` を作成します。

## クラスターをデプロイメントターゲットとして登録する

Argo CD は、_どの_ クラスターにデプロイするかを知る必要があります。オープンソースの Argo CD は実行されているクラスターを想定していますが、マネージド capability はクラスター外で実行され、組み込みのローカルターゲットがないため、このクラスターを明示的に登録します。Argo CD がデプロイメントターゲットとして認識する `Secret` として定義します。

::yaml{file="manifests/modules/fastpaths/eks-capabilities/argocd/cluster.yaml" paths="metadata.labels,stringData.name,stringData.server"}

1. `argocd.argoproj.io/secret-type: cluster` ラベルは、この Secret がデプロイメントターゲットを記述していることを Argo CD に伝えます。
2. ターゲットに明示的な名前 `eks-workshop` を付けます。
3. ターゲットは、通常の `https://kubernetes.default.svc` ではなく、EKS クラスター ARN (`$EKS_CLUSTER_AUTO_ARN`) によって識別されます。

Argo CD はすでにこのクラスターに同期できます。`prepare-environment` の間に、capability は cluster-admin ポリシーがアタッチされた IAM ロールの EKS アクセスエントリを作成しました。

`envsubst` でクラスター ARN を解決して適用します。

```bash
$ cat ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/argocd/cluster.yaml \
  | envsubst | kubectl apply -f -
secret/eks-workshop created
```

## catalog Application を作成する

次に、シードされた CodeCommit リポジトリを指す Argo CD `Application` を定義します。IAM Capability Role が `codecommit:GitPull` を許可しているため、Argo CD は HTTPS URL で **直接** リポジトリを読み取ります。リポジトリ Secret も、SSH キーも、設定する Git 認証情報ヘルパーもありません。

::yaml{file="manifests/modules/fastpaths/eks-capabilities/argocd/application.yaml" paths="spec.source,spec.destination,spec.syncPolicy"}

1. `source` は CodeCommit リポジトリ (`$EKS_CAP_CODECOMMIT_URL`) を指します。`path: catalog` はリポジトリ内のマニフェストディレクトリを選択します。
2. `destination.name: eks-workshop` は、登録したばかりのデプロイメントターゲットと一致します。
3. `syncPolicy.automated` と `prune` および `selfHeal` により、Argo CD は継続的にクラスターを Git に一致するように調整します。

ベースアプリケーションはすでに `kubectl` で `catalog` をデプロイしています。Argo CD が唯一の所有者になるように削除します。Argo CD は次のステップで Git からスタックを再作成します。

```bash
$ kubectl delete namespace catalog --ignore-not-found
namespace "catalog" deleted
```

`envsubst` でリポジトリ URL を解決して Application を適用します。

```bash
$ kubectl delete application catalog -n argocd --ignore-not-found
$ cat ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/argocd/application.yaml \
  | envsubst | kubectl apply -f -
application.argoproj.io/catalog created
```

Argo CD は新しい `Application` を取得し、CodeCommit からマニフェストをプルし、`catalog` Namespace を作成し、ワークロードをデプロイします。デフォルトの約3分間のポーリングを待たないように即座にリフレッシュをトリガーし、Application が `Healthy` を報告するまで待ちます。`Healthy` な Argo CD Application は、そのワークロードが正常にロールアウトされたことを意味するため、実行する別のロールアウトチェックはありません。

```bash timeout=600
$ kubectl annotate application catalog -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
$ kubectl wait --for=jsonpath='{.status.health.status}'=Healthy \
  application/catalog -n argocd --timeout=300s
application.argoproj.io/catalog condition met
```

最終的な同期とヘルス状態を確認します。

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```

UI にサインインした場合は、Applications ページの **catalog** タイルをクリックして、そのリソースツリーを開き、Argo CD がワークロードを調整するのを確認できます。

![Argo CD UI showing the catalog application resource tree](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in-app.png)

`catalog` サービスは GitOps によって配信されるようになりました。CodeCommit リポジトリにプッシュされた変更は、自動的にクラスターに調整されます。これは次に見ていきます。

