---
title: "より多くのワークロードの追加"
sidebar_position: 60
tmdTranslationSourceHash: 47bf999b2ab55006d4340855848db799
---

App of Appsパターンの基盤を設定したので、追加のワークロードHelmチャートをGitリポジトリに追加することができます。

アプリケーションチャートを追加した後のリポジトリ構造は次のようになります：

```text
.
|-- app-of-apps
|   |-- ...
|-- carts
|   `-- Chart.yaml
|-- catalog
|   `-- Chart.yaml
|-- checkout
|   `-- Chart.yaml
|-- orders
|   `-- Chart.yaml
`-- ui
    `-- Chart.yaml
```

アプリケーションチャートファイルをGitリポジトリディレクトリにコピーしましょう：

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/argocd/app-charts/* \
  ~/environment/argocd/
```

次に、これらの変更をGitリポジトリにコミットしてプッシュします：

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding apps charts"
$ git -C ~/environment/argocd push
```

appsアプリケーションを同期します：

```bash
$ argocd app sync apps
$ argocd app wait -l app.kubernetes.io/created-by=eks-workshop
```

Argo CDがプロセスを完了すると、すべてのアプリケーションはArgo CDのUI上で`Synced`状態になります：

![argocd-ui-apps.png](/docs/automation/gitops/argocd/app-of-apps/argocd-ui-apps-synced.webp)

各アプリケーションコンポーネントがデプロイされた新しい名前空間のセットが表示されるはずです：

```bash hook=deploy
$ kubectl get namespaces
NAME              STATUS   AGE
argocd            Active   18m
carts             Active   28s
catalog           Active   28s
checkout          Active   28s
default           Active   8h
gitea             Active   19m
kube-node-lease   Active   8h
kube-public       Active   8h
kube-system       Active   8h
orders            Active   28s
ui                Active   11m
```

デプロイされたワークロードの1つをより詳しく調べてみましょう。例えば、cartsコンポーネントを確認できます：

```bash
$ kubectl get deployment -n carts
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
carts   1/1     1            1           46s
```

これにより、App of Appsパターンを使用したGitOpsベースのデプロイメントが、すべてのマイクロサービスをクラスターに正常にデプロイしたことが確認されました。
