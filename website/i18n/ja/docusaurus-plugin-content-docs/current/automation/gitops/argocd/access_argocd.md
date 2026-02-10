---
title: "Argo CDのインストール"
sidebar_position: 10
weight: 10
tmdTranslationSourceHash: d56c4f4c50af1ff2a7b63644e2d44aeb
---

まずはクラスターにArgo CDをインストールしましょう：

```bash
$ helm repo add argo-cd https://argoproj.github.io/argo-helm
$ helm upgrade --install argocd argo-cd/argo-cd --version "${ARGOCD_CHART_VERSION}" \
  --namespace "argocd" --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/values.yaml \
  --wait
NAME: argocd
LAST DEPLOYED: [...]
NAMESPACE: argocd
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
[...]
```

このラボでは、Argo CDサーバーUIがロードバランサーを備えたKubernetesサービスを使用してクラスター外からアクセスできるように構成されています。URLを取得するには、次のコマンドを実行します：

```bash
$ export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
$ echo "Argo CD URL: https://$ARGOCD_SERVER"
Argo CD URL: https://acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com
```

ロードバランサーのプロビジョニングには時間がかかります。このコマンドを使用して、Argo CDが応答するまで待ちましょう：

```bash timeout=600 wait=60
$ curl --head -X GET --retry 20 --retry-all-errors --retry-delay 15 \
  --connect-timeout 5 --max-time 10 -k \
  https://$ARGOCD_SERVER
curl: (6) Could not resolve host: acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com
Warning: Problem : timeout. Will retry in 15 seconds. 20 retries left.
[...]
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 788
Content-Security-Policy: frame-ancestors 'self';
Content-Type: text/html; charset=utf-8
X-Frame-Options: sameorigin
X-Xss-Protection: 1
```

認証には、デフォルトのユーザー名は `admin` で、パスワードは自動生成されています。次のコマンドでパスワードを取得します：

```bash
$ export ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
$ echo "Argo CD admin password: $ARGOCD_PWD"
```

取得したURLと認証情報を使用してArgo CDのUIにログインします。以下のようなインターフェースが表示されます：

![argocd-ui](/docs/automation/gitops/argocd/argocd-ui.webp)

UIに加えて、Argo CDはアプリケーションを管理するための強力なCLIツール `argocd` を提供しています。

:::info
このラボでは、`argocd` CLIはすでにインストールされています。CLIツールのインストールについては、[こちらの手順](https://argo-cd.readthedocs.io/en/stable/cli_installation/)を参照してください。
:::

CLIを使用してArgo CDと対話するには、Argo CDサーバーで認証する必要があります：

```bash
$ argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PWD --insecure
'admin:login' logged in successfully
Context 'acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com' updated
```

最後に、アクセスを提供するためにGitリポジトリをArgo CDに登録します：

```bash
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ argocd repo add ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git \
  --ssh-private-key-path ${HOME}/.ssh/gitops_ssh.pem \
  --insecure-ignore-host-key --upsert --name git-repo
Repository 'ssh://...' added
```
