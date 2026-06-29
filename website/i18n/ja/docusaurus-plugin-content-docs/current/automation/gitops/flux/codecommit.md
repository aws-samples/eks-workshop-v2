---
title: "Gitリポジトリ"
sidebar_position: 5
tmdTranslationSourceHash: '55e2cc51116ce60babb9015e3b4ee9c4'
---

FluxはGitOps手法をKubernetesに適用し、Gitリポジトリを望ましいアプリケーション状態を定義するための唯一の信頼できる情報源として使用します。Fluxはクラスタを、Gitに保存された設定と同期し続け、プッシュされた変更を自動的に調整します。

このラボ環境では、AWS CodeCommitリポジトリがプロビジョニングされています。ただし、IDEから接続できるようにするには、いくつかのセットアップ手順を完了する必要があります。

まず、将来の操作中にSSH警告が表示されないように、CodeCommitのSSHキーをknown hostsファイルに追加しましょう。

```bash hook=ssh
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

次に、コミット用のユーザーIDをGitに設定しましょう。

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

これらの手順が完了すると、FluxとのGitOpsワークフローの基盤となるGitリポジトリが確立されます。

