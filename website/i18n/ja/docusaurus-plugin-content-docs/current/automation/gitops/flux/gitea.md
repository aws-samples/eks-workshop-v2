---
title: "Gitea のセットアップ"
sidebar_position: 5
kiteTranslationSourceHash: 81a4c85f3ba8bb568bde3044b3cdfecc
---

GitHubやGitLabの代わりとして、迅速かつ簡単な方法として[Gitea](https://gitea.com)を使用します。Giteaは軽量な自己ホスト型Gitサービスで、ユーザーフレンドリーなウェブインターフェースを提供し、独自のGitリポジトリを迅速に設定および管理することができます。これは、Fluxで探索するGitOpsワークフローに不可欠なKubernetesマニフェストを保存およびバージョン管理するための信頼できるソースとして機能します。

Helmを使用してEKSクラスターにGiteaをインストールしましょう：

```bash
$ helm upgrade --install gitea oci://docker.gitea.com/charts/gitea \
  --version "$GITEA_CHART_VERSION" \
  --namespace gitea --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/flux/gitea/values.yaml \
  --set "gitea.admin.password=${GITEA_PASSWORD}" \
  --wait
```

次に進む前に、Giteaが起動して実行されていることを確認します：

```bash timeout=300 wait=10
$ export GITEA_HOSTNAME=$(kubectl get svc -n gitea gitea-http -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  http://${GITEA_HOSTNAME}:3000
```

Gitとやり取りするためにSSHキーが必要になります。このラボの環境準備でSSHキーが作成されたので、Giteaにそれを登録するだけです：

```bash
$ curl -X 'POST' --retry 3 --retry-all-errors \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/keys" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"key\": \"$SSH_PUBLIC_KEY\",\"read_only\": true,\"title\": \"gitops\"}"
```

また、Fluxが使用するGiteaリポジトリも作成する必要があります：

```bash
$ curl -X 'POST' --retry 3 --retry-all-errors \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"flux\"}"
```

最後に、Gitがコミットに使用するIDを設定します：

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
$ git config --global core.sshCommand 'ssh -i ~/.ssh/gitops_ssh.pem'
```
