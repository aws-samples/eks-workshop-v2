---
title: "クラスターブートストラップ"
sidebar_position: 15
kiteTranslationSourceHash: 8817bad0efc303d4114e617ba7ee4a6d
---

ブートストラッププロセスでは、クラスターにFluxコンポーネントをインストールし、GitOpsを使用したクラスターオブジェクトの管理に関連するファイルをリポジトリに作成します。

クラスターをブートストラップする前に、Fluxはすべてが正しく設定されていることを確認するためのプリブートストラップチェックを実行することができます。以下のコマンドを実行して、Flux CLIにチェックを実行させましょう：

```bash
$ flux check --pre
> checking prerequisites
...
> prerequisites checks passed
```

これで、Giteaリポジトリを使用してEKSクラスターでFluxをブートストラップできます：

```bash
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ flux bootstrap git \
   --url=ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/flux.git \
   --branch=main \
   --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
   --network-policy=false --silent
```

上記のコマンドを分解してみましょう：

- まず、Fluxがその状態を保存するためにどのGitリポジトリを使用するかを指定します
- 次に、このFluxインスタンスが使用するGitの`branch`を指定します。一部のパターンでは同じGitリポジトリ内で複数のブランチを使用することがあります
- 認証情報を提供し、SSHではなくこれらの情報を使用してGitに認証するようFluxに指示します
- 最後に、このワークショップ専用に設定を簡略化するための構成を提供します

:::caution

上記のFluxのインストール方法は本番環境には適していません。本番環境では[公式ドキュメント](https://fluxcd.io/flux/installation/)に従ってください。

:::

次に、ブートストラッププロセスが正常に完了したことを確認するために、次のコマンドを実行しましょう：

```bash
$ flux get kustomization
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:6e6ae1d   False        True    Applied revision: main@sha1:6e6ae1d
```

これにより、Fluxが基本的なkustomizationを作成し、クラスターと同期していることが示されます。

