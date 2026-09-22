---
title: "Argo CDへのアクセス"
sidebar_position: 10
weight: 10
tmdTranslationSourceHash: 021b83cb38cbb1d7cf0cf9e297bf7e13
---

:::tip セットアップ済みの内容
**Amazon EKS Capability for Argo CD** がクラスターで有効化されています。Argo CDはAWSコントロールプレーンで実行されており、ワーカーノード上にArgo CDのPodはありません。**AWS IAM Identity Center** のユーザーが作成され、Argo CDへのADMINアクセス権が付与されています。
:::

Argo CDサーバーのURLを取得しましょう：

```bash
$ export ARGOCD_SERVER=$(aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_NAME \
  --capability-name argocd \
  --query 'capability.configuration.argoCd.serverUrl' \
  --output text)
$ echo "Argo CD URL: $ARGOCD_SERVER"
Argo CD URL: https://abcd1234.eks-capabilities.us-west-2.amazonaws.com
```

## Argo CDへのサインイン

Argo CDへのADMINアクセス権を持つIAM Identity Centerユーザーの認証情報を取得します：

```bash
$ echo "User:     $ARGOCD_IDC_USER"
$ echo "Password: $ARGOCD_IDC_PASSWORD"
```

パスワードが表示された場合は、そのまま使用できます。次のセクションにスキップしてください。

<details>
<summary>パスワードが空の場合は、ここを読んで<strong>ユーザーを自分でアクティベート</strong>してください</summary>

`ARGOCD_IDC_PASSWORD` が空の場合、ユーザーは存在するものの一度もサインインしていないことを意味します。これは、独自のアカウントでIAM Identity Centerをセットアップした場合に該当します。Identity Centerはパスワードなしでユーザーを作成し、パスワードを設定するAPIを提供していないため、最初のパスワードはサインインを通じて確立する必要があります。これは、管理者が新しいチームメンバーをオンボーディングする際と同じプロセスです。

ユーザーのワンタイムパスワードを生成します：

```bash test=false
$ echo "Console: $ARGOCD_IDC_CONSOLE_URL"
```

1. ブラウザで `$ARGOCD_IDC_CONSOLE_URL` を開き、管理者アクセス権を持つ認証情報を使用します
2. `$ARGOCD_IDC_USER` ユーザーをクリックします
3. **Reset password** を選択し、**Generate a one-time password and share the password with the user** を選択してから、表示されたパスワードをコピーします

そのワンタイムパスワードを使用して以下からサインインします。Identity Centerはすぐに永続的なパスワードの設定を求めます。パスワードを選択し、ラボの残りの部分で使用してください。

AWS主催のイベントでは、これらの手順は不要です。イベントのプロビジョニングがユーザーをアクティベートし、パスワードを保存するため、`ARGOCD_IDC_PASSWORD` はすでに入力されています。何らかの理由で空の場合は、プロビジョニングが書き込んだシークレットから直接読み取ることができます：

```bash test=false
$ aws secretsmanager get-secret-value \
  --secret-id $EKS_CLUSTER_NAME-argocd-idc \
  --query SecretString --output text | jq -r '.password'
```

</details>

## Argo CD UIへのアクセス

ブラウザで `$ARGOCD_SERVER` を開き、**Log in via SSO** をクリックしてから、`$ARGOCD_IDC_USER` としてサインインします。

:::note
IAM Identity Centerを自分でセットアップした場合、この最初のサインイン時にMFAデバイスの登録を求められることがあります。これは新しいユーザーに対するデフォルト設定です。認証アプリでデバイスを登録して続行するか、Identity Centerコンソールの **Settings → Authentication → Multi-factor authentication** でプロンプトをオフにしてください。

AWS主催のイベントではこれは発生しません。Identity Centerインスタンスはイベント用に作成され、プロビジョニング中にMFAプロンプトがオフになっています。ワークショップは、自身が作成したインスタンスに対してのみこれを実行し、既に存在していたインスタンスの設定を変更することはありません。
:::

以下のようなインターフェースが表示されます：

![argocd-ui](/docs/automation/gitops/argocd/argocd-ui.webp)

## Argo CD CLIの認証

このCapabilityは `argocd login` をサポートしていないため、サインインの代わりに、CLIはUIで生成する **アカウントトークン** で認証します：

1. 上で開いたArgo CD UIで、**Settings → Accounts → admin** に移動します
2. **Generate New Token** を選択します
3. 表示されたトークンをコピーします（再度表示されません）

次に、これらの環境変数を設定し、プレースホルダーの部分にトークンを貼り付けます：

```bash test=false
$ export ARGOCD_SERVER=$(echo $ARGOCD_SERVER | sed 's|^https://||')
$ export ARGOCD_AUTH_TOKEN="<paste-token-here>"
$ export ARGOCD_OPTS="--grpc-web"
```

CapabilityはエンドポイントをURLとして報告しますが、CLIは単なるホストを期待するため、最初の行でそれを削除します。`--grpc-web` が必要なのは、CapabilityがgRPC-Web経由でAPIを提供するためです。これら3つを設定すると、`argocd login` なしでCLIが動作します。

CLIが動作することを確認します：

```bash test=false
$ argocd app list
NAME  CLUSTER  NAMESPACE  PROJECT  STATUS  HEALTH  SYNCPOLICY  CONDITIONS
```

## EKSクラスターの登録

自己管理型のArgo CDインストール（クラスター内で実行され、APIサーバーへの直接アクセスがある）とは異なり、EKS Capabilityはクラスターの外部にあるAWSコントロールプレーンで実行されます。Argo CDがアプリケーションをデプロイする方法を認識できるように、EKSクラスターを明示的に登録する必要があります。

```bash
$ export CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME \
  --query 'cluster.arn' --output text)
$ argocd cluster add default --aws-cluster-name $CLUSTER_ARN --yes
INFO[0000] ServiceAccount "argocd-manager" created in namespace "kube-system"
INFO[0000] ClusterRole "argocd-manager-role" created
INFO[0000] ClusterRoleBinding "argocd-manager-role-binding" created
Cluster 'arn:aws:eks:us-west-2:...' added
```

これにより、Argo CDがクラスター上でアプリケーションリソースをデプロイおよび管理するために使用する `argocd-manager` ServiceAccountが `kube-system` に作成されます。クラスターはそのARNで識別されます。Argo CDアプリケーションを作成する際の宛先サーバーとして `$CLUSTER_ARN` を使用します。

## Gitリポジトリの登録

CodeCommit GitリポジトリをArgo CDに登録します：

```bash
$ argocd repo add $GITOPS_REPO_URL_ARGOCD \
  --ssh-private-key-path ${HOME}/.ssh/gitops_ssh.pem \
  --insecure-ignore-host-key --upsert --name git-repo
Repository 'ssh://...' added
```

