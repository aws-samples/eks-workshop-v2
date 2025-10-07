---
title: "クラスターの詳細を取得する"
sidebar_position: 21
kiteTranslationSourceHash: 536f30458507e29f7a4335e4d4f8394c
---

このセクションでは、Amazon Q CLIと[Amazon EKS用MCPサーバー](https://awslabs.github.io/mcp/servers/eks-mcp-server/)を使用して、自然言語コマンドでEKSクラスターの詳細を取得します。

:::info
コマンドラインの先頭に表示される `>` 記号は、Amazon Q CLIセッションがアクティブであることを示しています。このラボで提供されるプロンプトテキストをこのプロンプトで入力またはペーストできます。`>` プロンプトが表示されていない場合は、`q chat`コマンドを使用してAmazon Q CLIセッションを再起動してください。
:::

まず、EKSクラスターの詳細を取得しましょう。次のプロンプトを入力してください：

```text
Summarize the configuration of the eks-workshop EKS cluster
```

Amazon Q CLIがこの自然言語コマンドを処理する様子を観察してください。キャプション `Using tool: use_aws` で示されるように、様々な `aws` CLIコマンドが実行されていることがわかります。例えば：

```text
🛠️  Using tool: use_aws (trusted)
 ⋮
 ● Running aws cli command:

Service name: eks
Operation name: describe-cluster
Parameters:
- name: "eks-workshop"
Profile name: default
Region: us-west-2
Label: Get detailed configuration of the eks-workshop cluster
 ⋮
 ● Completed in 0.680s
```

このプロンプトでは、Amazon Q CLIはEKS MCPサーバーからのツールを使用する必要がありませんでした。

Markdownフォーマットで生成されたEKSクラスターの概要が表示されるはずです。サンプルを表示するには、以下のセクションを展開してください。

<details>
  <summary>サンプル応答を表示</summary>

```text
## EKS Workshop Cluster Configuration Summary

Here's a comprehensive overview of the eks-workshop cluster configuration:

Basic Information:
• **Name**: eks-workshop
• **Version**: Kubernetes 1.33
• **Platform Version**: eks.9
• **Status**: ACTIVE
• **Region**: us-west-2
• **Created**: July 30, 2025

Networking Configuration:
• **VPC ID**: vpc-066877a885d5047b9
• **Service IPv4 CIDR**: 172.16.0.0/16
• **IP Family**: IPv4
• **Subnets**: 6 subnets across multiple AZs
• **Security Groups**:
  • Additional: sg-037a5e8882d6773e0
  • Cluster: sg-0eb5e48614c13e6d8

API Endpoint Access:
• **Public Access**: Enabled (0.0.0.0/0)
• **Private Access**: Enabled
• **Endpoint**: https://CD839BD379D5C602A05C3F45CEBFB944.gr7.us-west-2.eks.amazonaws.com

Authentication & Authorization:
• **Authentication Mode**: API_AND_CONFIG_MAP (hybrid mode)
• **OIDC Provider**: Enabled
• **Service Role**: eksctl-eks-workshop-cluster-ServiceRole-ozN6Soi7RrfD

Node Group Configuration:
• **Name**: default
• **Instance Type**: m5.large
• **AMI Type**: AL2023_x86_64_STANDARD (Amazon Linux 2023)
• **Capacity Type**: ON_DEMAND
• **Scaling**: Min 3, Max 6, Desired 3 nodes
• **Subnets**: 3 private subnets
• **Update Strategy**: 50% max unavailable

Add-ons Installed:
• coredns (DNS resolution)
• eks-pod-identity-agent (Pod identity)
• kube-proxy (Network proxy)
• metrics-server (Resource metrics)
• vpc-cni (VPC networking)

Remote Network Configuration:
• **Remote Node Networks**: 10.52.0.0/16
• **Remote Pod Networks**: 10.53.0.0/16

Additional Features:
• **Logging**: All control plane logs disabled
• **Elastic Load Balancing**: Disabled
• **Upgrade Policy**: Extended support
• **Deletion Protection**: Disabled
• **Karpenter Discovery**: Enabled (tagged for auto-scaling)

The cluster is set up as a workshop environment with standard configurations suitable for learning and experimentation, managed by eksctl with CloudFormation stacks.
```

</details>

:::tip
GenAIモデルの基本的な特性により、Q CLIから得られる応答が、この実験やその他のQ CLI実験で示されている応答とは異なる可能性があります。同じプロンプトを複数回試しても、やや異なる応答が得られる場合があります。
:::

次に、EKS MCPサーバーを必要とするより複雑なクエリを試してみましょう：

```text
List all pods in the carts namespace with their IP addresses along with the host names they are running on.
```

EKS MCPサーバーが適切に構成されている場合、EKS MCPサーバーツールの使用を示す次の行が表示されます：

```text
🛠️ Using tool: list_k8s_resources from mcp server awslabseks_mcp_server
```

:::note
MCPサーバーツールを初めて使用する場合、Amazon Q CLIは許可を求めます：

```text
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:
```

このツールは読み取り専用の操作を実行するため、`t`を押してから`Enter`を押して、セッション中にこのツールを信頼できます。
:::

Q CLIは、ポッドをリストアップし、それぞれについての詳細情報を取得するために、EKS MCPサーバーからいくつかの異なるツールを使用します。その後、情報の要約を提供します。

<details>
  <summary>サンプル応答を表示</summary>

```text
## Pods in the carts namespace

Here are all the pods in the carts namespace with their IP addresses and host names:

| Pod Name | Pod IP | Host Name | Host IP |
|----------|--------|-----------|---------|
| carts-68d496fff8-bfvp8 | 10.42.158.113 | ip-10-42-140-175.us-west-2.compute.internal | 10.42.140.175 |
| carts-dynamodb-995f7768c-v4cct | 10.42.160.21 | ip-10-42-181-48.us-west-2.compute.internal | 10.42.181.48 |

### Pod Details:

carts-68d496fff8-bfvp8
• **Component**: Main carts service
• **Image**: public.ecr.aws/aws-containers/retail-store-sample-cart:1.2.1
• **Status**: Running
• **Created**: August 22, 2025

carts-dynamodb-995f7768c-v4cct
• **Component**: DynamoDB local database
• **Image**: amazon/dynamodb-local:1.25.1
• **Status**: Running
• **Created**: July 30, 2025

Both pods are running on different worker nodes in the EKS cluster, with the carts service pod on node ip-10-42-140-175 and the DynamoDB pod on node ip-10-42-181-48.
```

</details>

さらに複雑なタスク - テストポッドをデプロイしてインターネット接続をチェックしましょう：

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

この複雑なタスクは、Amazon Q CLIのいくつかの機能を示しています：

- 自然言語プロンプトの処理
- ステップバイステップの実行計画の作成
- MCPサーバーを通じて利用可能になっている適切なツールの選択
- 明確な要約の生成

<details>
  <summary>サンプル応答を表示</summary>

```text
## Internet Connectivity Test Results ✅

Test Status: SUCCESSFUL

The internet connectivity test completed successfully with the following results:

### Test Results Summary:
• **DNS Resolution**: ✅ SUCCESS
  • Successfully resolved google.com to both IPv4 (142.251.33.78) and IPv6 addresses
  • DNS server: 172.16.0.10 (CoreDNS in cluster)

• **HTTP Connectivity**: ✅ SUCCESS
  • Successfully connected to http://google.com

• **HTTPS Connectivity**: ✅ SUCCESS
  • Successfully connected to https://google.com

• **AWS API Connectivity**: ✅ SUCCESS
  • Successfully connected to https://ec2.us-west-2.amazonaws.com

### Test Pod Details:
• **Pod Name**: internet-test-pod
• **Namespace**: default
• **Node**: ip-10-42-110-8.us-west-2.compute.internal
• **Pod IP**: 10.42.121.194
• **Status**: Completed successfully and cleaned up

### Network Configuration Analysis:
Your EKS cluster has proper internet connectivity because:

1. NAT Gateway/Internet Gateway: The worker nodes are in private subnets with proper NAT Gateway configuration for outbound internet access
2. DNS Resolution: CoreDNS is working correctly (172.16.0.10)
3. Security Groups: Allow outbound traffic to the internet
4. VPC CNI: AWS VPC CNI is properly configured for pod networking
5. Route Tables: Properly configured to route traffic through NAT Gateway

The test pod has been successfully removed from the cluster. Your EKS cluster has full internet connectivity and is ready for workloads that require external access.
```

</details>

Q CLIセッションを終了するには、次のように入力します：

```text
/quit
```

次のセクションでは、クラスターのトラブルシューティングにAmazon Q CLIを使用する方法を探ります。

