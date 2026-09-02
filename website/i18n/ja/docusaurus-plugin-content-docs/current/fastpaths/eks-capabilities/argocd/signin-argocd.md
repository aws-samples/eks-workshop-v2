---
title: "Identity Center経由でArgo CDにサインインする"
sidebar_position: 15
tmdTranslationSourceHash: 'ce2402e707a9fc64da51a453b89e27e0'
---

マネージドArgo CD capabilityは、**AWS IAM Identity Center経由でのみ**認証を行います。ローカル`admin`アカウントや自動生成されたパスワードは存在しません。サインインする全ての人は、3つの組み込みArgo CDロール（`ADMIN`、`EDITOR`、`VIEWER`）のいずれかにマッピングされたIdentity Centerのアイデンティティを使用します。

このページでは、**初回セットアップ**と**初回サインイン**について説明します。この手順を完了すれば、このラボの残りの部分では、ここで設定したパスワードを再利用できます。

:::info AWSが主催するイベントでは、ステップ4にスキップしてください
イベントのプロビジョニングでは、作成したIdentity CenterインスタンスのMFAを緩和し、このユーザーの初回サインインを完了しています。そのため、ワンタイムパスワードを生成する必要はありません。パスワードはAWS Secrets Managerの`<cluster-name>-argocd-idc`に保存されています。

```bash test=false
$ aws secretsmanager get-secret-value --secret-id $EKS_CLUSTER_NAME-argocd-idc \
  --query SecretString --output text
```

ステップ2と3は、ご自身のアカウントでこのラボを実行する場合の手順です。
:::

:::caution
MFAを無効にすると、ワークショップユーザーだけでなく、IAM Identity Centerインスタンスの**全てのユーザー**のセキュリティが弱まります。個人用/開発用/テスト用アカウントでは許容されますが、本番アカウントや共有組織では**適用しないでください**。

イベントのプロビジョニングでは、自身が作成したインスタンスに対してのみこれを適用します。既存のインスタンスが見つかった場合は、それを採用し、サインインポリシーはそのままにします。なぜなら、他のワークロードのMFA設定を弱めることはワークショップの権限ではないからです。
:::

:::info
UIへのサインインは**オプション**です。Argo CDダッシュボードを探索することができますが、このラボの残りの部分はサインインなしで動作します。
:::

### 1. Identity Centerユーザーとグループ

ワークショップユーザーとグループは、環境ごとに1回作成され、Identity Centerとフェデレーションするすべてのcapabilityのラボで共有されます。アカウントとリージョンごとにIdentity Centerインスタンスは1つであるため、ラボごとにユーザーを作成すると、それぞれに対して個別の初回サインインが必要になります。これらは`prepare-environment`によってシェルにエクスポートされています。

```bash test=false
$ echo $EKS_CAP_ARGOCD_USER
eks-workshop
$ echo $EKS_CAP_ARGOCD_ADMIN_GROUP
eks-workshop-argocd-admins
```

事前作成されたユーザー

- `$EKS_CAP_ARGOCD_USER`: Argo CDの`ADMIN`ロールにマッピングされた管理者ユーザー。

事前作成されたグループ

- `$EKS_CAP_ARGOCD_ADMIN_GROUP`: 管理者権限を持つグループで、Argo CD capabilityに関連付けられています。

### 2. ワークショップのためのMFA無効化

ワークショップ中の認証体験を簡素化するため、Identity CenterユーザーのMulti-Factor Authentication（MFA）を無効化します。

AWSコンソールでIAM Identity Centerの設定を開きます。

<ConsoleButton url="https://console.aws.amazon.com/singlesignon/home#!/settings" service="console" label="Identity Centerの設定を開く"/>

:::caution
IAM Identity Centerはリージョンサービスです。続行する前に、コンソールのリージョンセレクター（右上）がワークショップクラスターを作成したリージョンと一致していることを確認してください。「Enable IAM Identity Center」画面が表示された場合、間違ったリージョンにいます。リージョンを切り替えると、既存のインスタンスが表示されます。
:::

次にMFAを無効にします。

1. **Settings**ページで、**Authentication**セクションを見つけ、多要素認証の**Configure**を選択します。

   ![Configure MFA](/img/fastpaths/eks-capabilities/argocd/sso_mfa_navigate.png)

1. MFA設定で**Never (disabled)**を選択し、変更を保存します。

   ![SSO MFA Disable](/img/fastpaths/eks-capabilities/argocd/sso_mfa_disable.png)

### 3. 管理者ユーザーの一時パスワードを生成する

Identity Centerの新しいユーザーは、管理者が一時パスワードを生成する必要があります。

まず、コンソールで探すべき正確なユーザー名を表示します。Terraformはクラスター名に基づいてユーザーに名前を付けたため、コンソールには文字通り`$EKS_CAP_ARGOCD_USER`とは表示されません。

```bash test=false
$ echo $EKS_CAP_ARGOCD_USER
eks-workshop
```

Identity Centerの**Users**リストを開きます。

<ConsoleButton url="https://console.aws.amazon.com/singlesignon/home#!/users" service="console" label="Identity Centerユーザーを開く"/>

1. 先ほど表示した名前と一致するユーザー（例：`eks-workshop`）を見つけて選択します。

   ![Select Argoadmin](/img/fastpaths/eks-capabilities/argocd/argoadmin_select.png)

1. パスワードのリセット
   - 「Reset password」をクリック
   - 「Generate a one-time password」を選択

   ![Argoadmin Reset Password](/img/fastpaths/eks-capabilities/argocd/argoadmin_select_resetpassword.png)

1. 生成されたワンタイムパスワードをコピーし、**安全な場所に貼り付けて保存**します（スクラッチファイルやメモ）。次のステップでサインインする際に必要になります。また、ここで生成するとクリップボードが上書きされます。

   ![Copy Reset Argoadmin Password](/img/fastpaths/eks-capabilities/argocd/argoadmin_copy_resetpassword.png)

### 4. Argo CDへの初回サインイン

新しいブラウザタブでArgo CDのURLを開きます。capabilityがそれを公開しているため、環境で期待するのではなく、EKS APIに問い合わせます。

```bash test=false
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ARGOCD_CAPABILITY \
  --query 'capability.configuration.argoCd.serverUrl' --output text
```

1. **Log in via AWS Identity Center**をクリックします。
2. **Username:** `$EKS_CAP_ARGOCD_USER`の値を入力します。**Next**をクリックします。
3. **Password:** ステップ3でコピーしたワンタイムパスワードを入力します。**Sign in**をクリックします。
4. Identity Centerは初回サインイン時に**Set new password**画面を強制します。任意の新しいパスワードを選択して確認します。
5. 新しいパスワードを設定すると、`ADMIN`としてArgo CDの**Applications**ビューにリダイレクトされます。

![Identity Centerサインイン後のArgo CD UI](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in.png)

:::tip
UIには**Amazon EKSコンソール**からもアクセスできます。クラスターを選択し、**Capabilities**タブを選択し、**Argo CD**を選択してから、**Open Argo CD UI**を選択します。どちらの経路も同じIdentity Centerサインインを経由します。
:::

これでこのラボの残りの部分を進める準備が整いました。

<!-- ## Troubleshooting

**"Register MFA device"画面が"Set new password"の代わりに表示される。** ステップ2でMFAが完全に無効化されていません。**Identity Center → Settings → Authentication**に戻り、新しいリロードで**Prompt users for MFA**が`Never (disabled)`と表示されていることを確認してから、再度サインインしてください。

**"Incorrect username or password"。** OTPは1回限りの使用で、すぐに期限切れになります。ステップ3で再生成して、もう一度試してください。OTPにはシェル特殊文字（例：`^&#<>`）が含まれることがあり、一部のターミナルでペースト時に混乱を招く可能性があるため、ペーストが乱れているように見える場合は手動で入力してください。

**"It's not you, it's us"。** Identity Centerがユーザーをアクティブ化できませんでした。Reset password → "Generate a one-time password"（メールリンクオプションではなく）を使用して、メールの往復をバイパスしてください。

**`prepare-environment`中の`Caller does not have permission to perform sso:CreateApplication`。** IDEロールには、`lab/iam/policies/eks-capabilities.yaml`で提供されるSSOおよびIdentity Storeのパーミッションが必要です。標準のワークショップIDE外で実行している場合は、そのポリシーをランナーロールにアタッチしてください。 -->

