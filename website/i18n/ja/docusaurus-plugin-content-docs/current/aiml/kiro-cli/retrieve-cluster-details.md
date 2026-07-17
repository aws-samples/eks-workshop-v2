---
title: "クラスター詳細の取得"
sidebar_position: 21
tmdTranslationSourceHash: '0f706fd9aca9f31ce820a94f8ac1ca57'
---

このセクションでは、Kiro CLI と [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) を使用して、自然言語コマンドで EKS クラスターの詳細を取得します。

:::info
コマンドラインの先頭にある `❯` 記号は、Kiro CLI セッションがアクティブであることを示しています。このラボで提供されるプロンプトテキストを、このプロンプトで入力またはペーストできます。`❯` プロンプトが表示されない場合は、`kiro-cli chat` コマンドを使用して Kiro CLI セッションを再起動してください。
:::

まず、EKS クラスターの詳細を取得してみましょう。以下のプロンプトを入力してください：

```text
Summarize the configuration of the eks-workshop EKS cluster.
```

Kiro CLI がこの自然言語コマンドをどのように処理するか観察してください。デフォルトで利用可能な `use_aws` MCP ツールへのアクセス許可を求められます。例えば：

```text
↓ manage_eks_stacks
    ╰ operation=describe, cluster_name=eks-workshop
● use_aws
    ╰ service_name=eks, operation_name=describe-cluster, region=us-east-1, label=Describe eks-workshop EKS cluster
  esc to cancel

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 manage_eks_stacks requires approval
   Yes, single permission             
 ❯ Trust, always allow in this session
   No (Tab to edit)                   
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 ESC to close · ↑↓ to navigate · ↵ to select · Tab to edit
```

`Yes` または `Trust` を選択して、Kiro が選択したツールを使用できるようにします。このプロンプトでは、Kiro CLI は EKS MCP server のツールを使用する必要はありませんでした。

Kiro は必要な詳細を取得するためにさまざまなコマンドを実行し、Markdown 形式で生成された EKS クラスターのサマリーを表示します。サンプルを確認するには、以下のセクションを展開してください。

<details>
  <summary>サンプルレスポンスを展開</summary>

```text
  Here's a summary of the eks-workshop EKS cluster configuration:
  
  Cluster Overview
  
  ┌─────────────────────┬──────────────────────────────────┐
  │ Property            │ Value                            │
  ├─────────────────────┼──────────────────────────────────┤
  │ Region              │ us-west-2                        │
  ├─────────────────────┼──────────────────────────────────┤
  │ Status              │ ACTIVE                           │
  ├─────────────────────┼──────────────────────────────────┤
  │ Kubernetes version  │ 1.33                             │
  ├─────────────────────┼──────────────────────────────────┤
  │ Platform version    │ eks.41                           │
  ├─────────────────────┼──────────────────────────────────┤
  │ Created             │ 2026-07-01 (today)               │
  ├─────────────────────┼──────────────────────────────────┤
  │ Created by          │ eksctl 0.222.0 (eks-workshop-v2) │
  ├─────────────────────┼──────────────────────────────────┤
  │ Authentication mode │ API                              │
  ├─────────────────────┼──────────────────────────────────┤
  │ Support type        │ EXTENDED                         │
  ├─────────────────────┼──────────────────────────────────┤
  │ Control plane tier  │ Standard                         │
  └─────────────────────┴──────────────────────────────────┘
  
  Networking
  
  - VPC: vpc-0e572856d73a646b7 (6 subnets)
  - Service CIDR: 172.16.0.0/16 (IPv4)
  - API endpoint: Public + Private access (public open to 0.0.0.0/0)
  - Remote node network: 10.52.0.0/16
  - Remote pod network: 10.53.0.0/16
  
  Node Group: default
  
  ┌─────────────────┬───────────────────────────┐
  │ Property        │ Value                     │
  ├─────────────────┼───────────────────────────┤
  │ Instance type   │ m5.large                  │
  ├─────────────────┼───────────────────────────┤
  │ AMI             │ AL2023_x86_64_STANDARD    │
  ├─────────────────┼───────────────────────────┤
  │ Capacity        │ ON_DEMAND                 │
  ├─────────────────┼───────────────────────────┤
  │ Scaling         │ min 3 / desired 3 / max 6 │
  ├─────────────────┼───────────────────────────┤
  │ Subnets         │ 3 private subnets         │
  ├─────────────────┼───────────────────────────┤
  │ Update strategy │ 50% max unavailable       │
  └─────────────────┴───────────────────────────┘
  
  Addons
  
  - coredns
  - kube-proxy
  - metrics-server
  - vpc-cni
  
  Logging
  
  Control plane logging is disabled (api, audit, authenticator, controllerManager, scheduler all off).
  
  Notable Tags
  
  - karpenter.sh/discovery: eks-workshop — cluster is tagged for Karpenter discovery
  - created-by: eks-workshop-v2 — provisioned by the EKS Workshop v2 tooling

▸ Credits: 0.59 • Time: 9m 53s
```
</details>

:::info
GenAI モデルの基本的な特性として、このラボおよび他の Kiro CLI ラボで提供されるプロンプトに対して、Kiro CLI から得られるレスポンスが、ここで示されているものと異なる可能性があることは通常のことです。同じプロンプトを複数回試した場合でも、やや異なるレスポンスが得られる可能性があります。
:::

次に、EKS MCP server を必要とする、より複雑なクエリを試してみましょう：

```text
List all pods in the carts namespace with their IP addresses along with the host names they are running on.
```

EKS MCP server が適切に設定されている場合、EKS MCP server ツールの使用を示す次の行が表示されます：

```text
↓ list_k8s_resources
    ╰ cluster_name=eks-workshop, kind=Pod, api_version=v1, namespace=carts

──────────────────────────────────────────────────────────────────────────
 list_k8s_resources requires approval
 ❯ Yes, single permission             
   Trust, always allow in this session
   No (Tab to edit)                   
──────────────────────────────────────────────────────────────────────────
 ESC to close · ↑↓ to navigate · ↵ to select · Tab to edit

```
`Yes` または `Trust` を選択して、Kiro がこのツールを使用できるようにします。

Kiro CLI は、EKS MCP server のいくつかの異なるツールを使用して Pod をリストし、それぞれの詳細情報を取得する可能性があります。その後、情報のサマリーを提供します。

<details>
  <summary>サンプルレスポンスを展開</summary>

```text
  Here are the pods in the carts namespace:
  
  ┌────────────────────────────────┬──────────────┬─────────────────────────────────────────────┬───────────────┐
  │ Pod                            │ Pod IP       │ Node (Host)                                 │ Host IP       │
  ├────────────────────────────────┼──────────────┼─────────────────────────────────────────────┼───────────────┤
  │ carts-68d496fff8-srf6w         │ 10.42.120.84 │ ip-10-42-109-241.us-west-2.compute.internal │ 10.42.109.241 │
  ├────────────────────────────────┼──────────────┼─────────────────────────────────────────────┼───────────────┤
  │ carts-dynamodb-995f7768c-mzwgh │ 10.42.135.85 │ ip-10-42-131-80.us-west-2.compute.internal  │ 10.42.131.80  │
  └────────────────────────────────┴──────────────┴─────────────────────────────────────────────┴───────────────┘
  
  Both pods are Running and Ready. The carts service pod and the DynamoDB local pod are scheduled on different nodes.

▸ Credits: 0.35 • Time: 5m 24s
```

</details>

さらに複雑なタスクを実行してみましょう - テスト Pod をデプロイしてインターネット接続を確認します：

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

Kiro が必要なツールを使用してこの複雑なタスクを完了できるように承認してください。Kiro CLI の以下の機能を確認できるはずです：

- 自然言語プロンプトの処理
- ステップバイステップの実行計画の作成
- MCP server を通じて利用可能なツールから適切なツールを選択
- 明確なサマリーの生成

<details>
  <summary>サンプルレスポンスを展開</summary>

```text
  Internet connectivity test passed. The test pod successfully reached https://www.google.com and received an HTTP 200 response. The pod has been cleaned up.
  
  Your cluster's pods have working outbound internet access, meaning DNS resolution, NAT gateway (or equivalent), and security group/NACL rules are all functioning correctly.

▸ Credits: 0.40 • Time: 3m 40s

```

</details>

Kiro CLI セッションを終了するには、以下を入力してください：

```text
/quit
```

次のセクションでは、Kiro CLI をクラスターのトラブルシューティングに使用する方法を探ります。

