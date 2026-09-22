---
title: "GitOps アップデートのトリガー"
sidebar_position: 40
tmdTranslationSourceHash: 7ddbac31347aac7377132fd8a4ed7e0e
---

自動同期が有効になっているため、Git リポジトリが `catalog` の信頼できる情報源になりました。変更をロールアウトするには、クラスターには一切触れません。CodeCommit でマニフェストを変更し、Argo CD に調整させるだけです。`catalog` Deployment のレプリカ数を 1 から 2 にスケールし、デプロイを確認しましょう。

まず、CodeCommit リポジトリを IDE にクローンします。`git-remote-codecommit` を使用すると、SSH キーや Git 認証情報なしで、`codecommit::` リモートヘルパーを通じて現在の AWS 認証情報を使用して `git` が CodeCommit に対して認証できるようになります。最初に `rm -rf` でこれまでのクローンをクリアするため、このステップは安全に再実行できます：

```bash
$ rm -rf ~/environment/catalog-gitops
$ git clone codecommit::${AWS_REGION}://${EKS_CAP_CODECOMMIT_REPO} ~/environment/catalog-gitops
```

リポジトリ内の現在のレプリカ数を確認します：

```bash
$ grep 'replicas:' ~/environment/catalog-gitops/catalog/deployment.yaml
  replicas: 1
```

1 から 2 に更新します：

```bash
$ sed -i 's|replicas: 1|replicas: 2|' \
  ~/environment/catalog-gitops/catalog/deployment.yaml
$ grep 'replicas:' ~/environment/catalog-gitops/catalog/deployment.yaml
  replicas: 2
```

変更をコミットしてプッシュします。ブロック全体を 1 つの連結されたコマンドとして実行してください。Git はコミット前にこのリポジトリで `user.email` と `user.name` が設定されている必要があり、連結（`&&`）によって `git commit` が実行される前にアイデンティティが設定されていることが保証されます：

```bash
$ cd ~/environment/catalog-gitops && \
  git config user.email "you@eksworkshop.com" && \
  git config user.name "EKS Workshop" && \
  git add catalog/deployment.yaml && \
  (git diff --cached --quiet \
     || git commit -m "Scale catalog to 2 replicas") && \
  git push origin main
```

:::note
ブロックを分割して `git commit` を単独で実行すると、`fatal: unable to auto-detect email address` というエラーが表示されることがあります。これは、同じシェルで `git config` 行がまだ実行されていないことを意味します。上記の連結されたブロックを再実行してください。
:::

これが変更のすべてです：Git への単一のコミットです。Argo CD は独自のスケジュールでリポジトリをポーリングし、新しいリビジョンを検出すると調整します。次のポーリングまで最大約 3 分待つのを避けるために、今すぐ Application をリフレッシュするよう Argo CD に依頼します：

```bash
$ kubectl annotate application catalog -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
application.argoproj.io/catalog annotated
```

2 つ目のレプリカでロールアウトが完了するのを待ちます。Argo CD がまだ変更を調整している可能性があり（Amazon EKS Auto Mode が追加のレプリカ用にノードをスケールアップしている可能性があり）、まず `catalog` Deployment が存在するのを待ってから、ロールアウトを待ちます：

```bash timeout=300
$ kubectl wait --for=create -n catalog deployment/catalog --timeout=120s
deployment.apps/catalog condition met
$ kubectl rollout status -n catalog deployment/catalog --timeout=180s
deployment "catalog" successfully rolled out
```

実行中の Deployment が 2 つのレプリカを持っていることを確認します：

```bash
$ kubectl get deployment catalog -n catalog \
  -o jsonpath='{.status.readyReplicas}{"\n"}'
2
```

Argo CD が新しいリビジョンに調整され、正常であることを報告していることも確認できます：

```bash
$ kubectl get application catalog -n argocd \
  -o jsonpath='{.status.sync.status}{"/"}{.status.health.status}{"\n"}'
Synced/Healthy
```

UI にサインインしている場合は、**catalog** タイルをクリックしてリソースツリーを開き、2 つ目のレプリカが表示されるのを確認してください：

![調整された catalog アプリケーションを表示する Argo CD UI](/img/fastpaths/eks-capabilities/argocd/argocd-ui-1.22-app.png)

:::tip
`selfHeal` が有効になっているため、Deployment を直接編集してみてください。例えば `kubectl scale -n catalog deployment/catalog --replicas=3` を実行します。Argo CD は Git からのドリフトを検出し、それを元に戻します。これは、クラスターではなく Git が信頼できる情報源であるためです。
:::

Argo CD ラボは以上です。完全に管理された GitOps パイプラインを通じて `catalog` サービスを配信しました：CodeCommit へのプッシュがクラスター上で調整されたロールアウトになり、`kubectl apply` も自己管理型 Argo CD の運用も必要ありませんでした。

次に、**kro capability** を使用して、完全な `carts` スタックを単一のリソースグラフとして宣言します。

