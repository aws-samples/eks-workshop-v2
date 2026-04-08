---
title: "アプリケーションの更新"
sidebar_position: 40
tmdTranslationSourceHash: 0f81209f4be7d294a1527a3ab5b6702d
---

Argo CDでアプリケーションをデプロイしたので、GitOpsの原則を使用して設定を更新する方法を探ってみましょう。この例では、Helmの値を使用して`ui`デプロイメントの`replicas`の数を1から3に増やします。

まず、レプリカの数を設定する`values.yaml`ファイルを作成します：

::yaml{file="manifests/modules/automation/gitops/argocd/update-application/values.yaml"}

この設定ファイルをGitリポジトリディレクトリにコピーしましょう：

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/argocd/update-application/values.yaml \
  ~/environment/argocd/ui
```

このファイルを追加した後、Gitディレクトリの構造は次のようになるはずです：

```bash
$ tree ~/environment/argocd
`-- ui
    |-- Chart.yaml
    `-- values.yaml
```

次に、変更をコミットしてGitリポジトリにプッシュします：

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Update UI service replicas"
$ git -C ~/environment/argocd push
```

この時点で、Argo CDはリポジトリ内のアプリケーション状態が変更されたことを検出します。Argo CDのUIで`Refresh`をクリックしてから`Sync`をクリックするか、`argocd` CLIを使用してアプリケーションを同期させることができます：

```bash
$ argocd app sync ui
$ argocd app wait ui --timeout 120
```

同期が完了すると、UIデプロイメントには3つのポッドが実行されているはずです：

![argocd-update-application](/docs/automation/gitops/argocd/argocd-update-application.webp)

更新が成功したことを確認するために、デプロイメントとポッドのステータスを確認しましょう：

```bash hook=update
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           3m33s
$ kubectl get pod -n ui
NAME                 READY   STATUS    RESTARTS   AGE
ui-6d5bb7b95-hzmgp   1/1     Running   0          61s
ui-6d5bb7b95-j28ww   1/1     Running   0          61s
ui-6d5bb7b95-rjfxd   1/1     Running   0          3m34s
```

これは、GitOpsがバージョン管理を通じて設定変更を行う方法を示しています。リポジトリを更新してArgo CDと同期することで、Kubernetes APIと直接対話することなく、UIデプロイメントを正常にスケーリングすることができました。
