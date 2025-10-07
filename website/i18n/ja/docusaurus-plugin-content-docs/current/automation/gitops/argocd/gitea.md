---
title: "Gitea のセットアップ"
sidebar_position: 5
kiteTranslationSourceHash: 65f16f55be12d2b448d3eac30d9a4841
---

GitHub や GitLab の代わりに、迅速で簡単な代替手段として [Gitea](https://gitea.com) を使用します。Gitea は軽量な自己ホスト型 Git サービスで、ユーザーフレンドリーなウェブインターフェースを提供し、独自の Git リポジトリを迅速にセットアップおよび管理することができます。これは、Argo CD で探索する GitOps ワークフローに不可欠な Kubernetes マニフェストの保存とバージョン管理のための信頼できるソースとして機能します。

Helm を使用して Gitea を EKS クラスターにインストールしましょう：

```bash
$ helm upgrade --install gitea oci://docker.gitea.com/charts/gitea \
  --version "$GITEA_CHART_VERSION" \
  --namespace gitea --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/gitea/values.yaml \
  --set "gitea.admin.password=${GITEA_PASSWORD}" \
  --wait
```

次に進む前に Gitea が稼働していることを確認しましょう：

```bash timeout=300
$ export GITEA_HOSTNAME=$(kubectl get svc -n gitea gitea-http -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  http://${GITEA_HOSTNAME}:3000
```

Git との対話には SSH キーが必要になります。このラボの環境準備で作成されたキーを Gitea に登録する必要があります：

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/keys" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"key\": \"$SSH_PUBLIC_KEY\",\"read_only\": true,\"title\": \"gitops\"}"
```

そして、Argo CD が使用する Gitea リポジトリも作成する必要があります：

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"argocd\"}"
```

次に、Git がコミットに使用する ID を設定します：

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
$ git config --global core.sshCommand 'ssh -i ~/.ssh/gitops_ssh.pem'
```

最後にリポジトリをクローンして、初期構造をセットアップしましょう：

```bash hook=clone
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ git clone ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git ~/environment/argocd
$ git -C ~/environment/argocd checkout -b main
Switched to a new branch 'main'
$ touch ~/environment/argocd/.gitkeep
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Initial commit"
$ git -C ~/environment/argocd push --set-upstream origin main
```

