---
title: "Gitリポジトリ"
sidebar_position: 5
tmdTranslationSourceHash: '1c46875c4edc7a8dd88fed12dd97565a'
---

Argo CDはGitOpsの方法論をKubernetesに適用し、Gitリポジトリを望ましいアプリケーション状態を定義する唯一の信頼できる情報源として使用します。Argo CDを使用すると、アプリケーションをデプロイし、その健全性を監視し、望ましい状態と自動的に同期させることができます。Kubernetesマニフェストは、いくつかの方法で指定できます：

- Kubernetes YAMLファイル
- Kustomizeアプリケーション
- Helmチャート
- Jsonnetファイル

ラボ環境では、AWS CodeCommitリポジトリがプロビジョニングされています。ただし、IDEが接続できるようにするには、いくつかのセットアップ手順を完了する必要があります。

まず、CodeCommitのSSHキーをknown hostsファイルに追加して、今後の操作中にSSH警告が表示されないようにしましょう：

```bash hook=ssh
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

次に、コミット用のユーザーIDでGitを設定しましょう：

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

次に、リポジトリをクローンして、初期構造をセットアップしましょう：

```bash
$ git clone $GITOPS_REPO_URL_ARGOCD ~/environment/argocd
$ git -C ~/environment/argocd checkout -b main
Switched to a new branch 'main'
$ touch ~/environment/argocd/.gitkeep
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Initial commit"
$ git -C ~/environment/argocd push --set-upstream origin main
```

これらの手順を完了したことで、Argo CDとのGitOpsワークフローの基盤となるGitリポジトリを確立しました。

