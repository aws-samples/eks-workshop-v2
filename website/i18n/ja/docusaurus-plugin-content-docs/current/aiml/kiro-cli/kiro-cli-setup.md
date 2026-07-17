---
title: "セットアップ"
sidebar_position: 20
tmdTranslationSourceHash: '2ac9ca7bcf28b86b835dc4e3c28853fc'
---

このセクションでは、Kiro CLI と [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) を設定し、自然言語コマンドを使用して EKS クラスターを操作できるようにします。

:::info
Kiro CLI は、一般的な開発および運用タスクのために生成 AI 機能を活用します。その機能は、特定の知識のために構築された専用の MCP server を追加することで強化できます。このセクションでは、Kiro CLI と Amazon EKS MCP server を使用します。AWS が提供する MCP server のカタログは[こちら](https://awslabs.github.io/mcp/)で確認でき、同様の方法で Kiro CLI と組み合わせて使用できます。
:::

まず、お使いのオペレーティングシステムと CPU アーキテクチャ用の Kiro CLI リリースをダウンロードします:

```bash
$ ARCH=$(arch)
$ mkdir $HOME/tmp
$ curl --proto '=https' --tlsv1.2 \
  -sSf https://desktop-release.q.us-east-1.amazonaws.com/2.10.0/kirocli-${ARCH}-linux.zip \
  -o $HOME/tmp/kirocli.zip
```

Kiro CLI をインストールします:

```bash
$ unzip $HOME/tmp/kirocli.zip -d $HOME/tmp
$ bash $HOME/tmp/kirocli/install.sh --no-confirm
```

インストールを確認します:

```bash
$ kiro-cli version
kiro-cli 2.10.0
```

次に、Amazon EKS MCP server を使用して Kiro CLI を設定します。使用する設定は次のとおりです:

```file
manifests/modules/aiml/kiro-cli/setup/eks-mcp.json
```

MCP server を設定し、必要な `uvx` ツールをインストールします:

:::info
`uvx` は、uv パッケージマネージャーに付属する Python パッケージランナーツールです。グローバルにインストールすることなく、Python パッケージを直接実行します。その後、Node.js の `npx` に似た、分離された環境で Python ツールをダウンロードして実行しますが、Python パッケージ用です。
:::

```bash
$ mkdir -p $HOME/.kiro/settings
$ cp ~/environment/eks-workshop/modules/aiml/kiro-cli/setup/eks-mcp.json $HOME/.kiro/settings/mcp.json
$ curl -LsSf https://astral.sh/uv/0.11.26/install.sh | sh
```

Kiro CLI を使用するには、AWS Builder ID または Pro ライセンスサブスクリプションを使用して認証する必要があります。

:::tip
無料の AWS Builder ID は、[これらの手順](https://docs.aws.amazon.com/signin/latest/userguide/create-aws_builder_id.html)に従って作成できます。この Builder ID は、Kiro CLI の個人使用にも使用できます。
:::

```bash test=false
$ kiro-cli login --use-device-flow
? Select login method >
> Use with Builder ID
  Use with Google
  Use with GitHub
  Use with Your Organization
```

希望するログイン方法を選択し、プロンプトに従ってログインします。まだ Kiro アカウントをお持ちでない場合は、Google または GitHub アカウントを使用して無料トライアルアカウントを作成できます。Google または GitHub アカウントをリンクするには、指定された URL を開く必要があります。

:::tip
Kiro 無料トライアルアカウントでは、最初に 50 の Kiro クレジットが付与されます。このラボでは 5 クレジット未満しか必要としない場合があります。そのため、このワークショップの外でもそのアカウントを使用して、他のプロジェクトで Kiro トライアルを継続できます。kiro-cli セッション内で `/usage` コマンドを使用して、使用したクレジットを確認できます。Kiro 無料トライアルアカウントを作成するために支払い情報は必要ありません。
:::

セッションを初期化して、MCP server が利用可能であることを確認しましょう:

```bash test=false
$ kiro-cli chat
```

EKS MCP server が提供するツールを確認するには、次を実行します:

```text
/tools
```
次のような出力が表示されます:

![list-mcp-tools](/img/aiml/kiro-cli/list-mcp-tools.jpg)

出力には次のものが表示されます:

1. `/tools` のような Kiro コマンドを実行できるスペース。`/` を入力すると、そのようなコマンドがすべて表示されます。Kiro コマンドの詳細については、[こちら](https://kiro.dev/docs/cli/reference/slash-commands/#available-commands)をご覧ください。
2. EKS MCP server が提供するツールのリスト

:::info
ツールが `approval required` とマークされている場合、Kiro CLI はそれを使用する前に許可を求めます。これは特に、リソースを作成、更新、または削除できるツールに対する安全対策です。LLM は間違いを犯す可能性があるため、潜在的に破壊的なアクションが実行される前に、それらを確認する機会が与えられます。
:::

同じ手順に従って、追加機能のために [AWS Labs の他の MCP server](https://awslabs.github.io/mcp/) を追加できます。このラボでは、設定した EKS MCP server のみが必要です。

次のセクションでは、Kiro CLI を使用して EKS クラスターに関する情報を取得します。

