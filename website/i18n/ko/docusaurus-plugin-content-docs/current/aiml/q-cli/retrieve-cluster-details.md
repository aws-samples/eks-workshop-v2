---
title: "클러스터 세부 정보 검색"
sidebar_position: 21
tmdTranslationSourceHash: '536f30458507e29f7a4335e4d4f8394c'
---

이 섹션에서는 Amazon Q CLI와 [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/)를 사용하여 자연어 명령으로 EKS 클러스터의 세부 정보를 검색합니다.

:::info
명령줄 시작 부분의 `>` 기호는 활성 Amazon Q CLI 세션이 있음을 나타냅니다. 이 프롬프트에서 이 실습에서 제공하는 프롬프트 텍스트를 입력하거나 붙여넣을 수 있습니다. `>` 프롬프트가 표시되지 않으면 `q chat` 명령을 사용하여 Amazon Q CLI 세션을 다시 시작하세요.
:::

먼저 EKS 클러스터에 대한 세부 정보를 가져와 보겠습니다. 다음 프롬프트를 입력하세요:

```text
Summarize the configuration of the eks-workshop EKS cluster
```

Amazon Q CLI가 이 자연어 명령을 어떻게 처리하는지 관찰하세요. `Using tool: use_aws`라는 캡션으로 표시되는 다양한 `aws` CLI 명령을 실행하는 것을 볼 수 있습니다. 예를 들어:

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

이 프롬프트의 경우 Amazon Q CLI는 EKS MCP server의 도구를 사용할 필요가 없었습니다.

Markdown 형식으로 생성된 EKS 클러스터 요약을 볼 수 있습니다. 아래 섹션을 확장하여 샘플을 확인하세요.

<details>
  <summary>샘플 응답을 보려면 확장하세요</summary>

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
GenAI 모델의 기본 특성상, Q CLI에서 얻는 응답이 이 실습 및 다른 Q CLI 실습에서 주어진 프롬프트에 대해 표시된 것과 다를 수 있으며 이는 정상입니다. 동일한 프롬프트를 여러 번 시도하면 다소 다른 응답을 얻을 수 있습니다.
:::

이제 EKS MCP server가 필요한 더 복잡한 쿼리를 시도해 보겠습니다:

```text
List all pods in the carts namespace with their IP addresses along with the host names they are running on.
```

EKS MCP server가 올바르게 구성되어 있으면 EKS MCP server 도구를 사용하고 있음을 나타내는 다음 줄이 표시됩니다:

```text
🛠️ Using tool: list_k8s_resources from mcp server awslabseks_mcp_server
```

:::note
MCP server 도구를 처음 사용할 때 Amazon Q CLI는 권한을 요청합니다:

```text
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:
```

이 도구는 읽기 전용 작업을 수행하므로 세션에 대해 이 도구를 신뢰하려면 `t`를 누른 다음 `Enter`를 누를 수 있습니다.
:::

Q CLI는 Pod를 나열한 다음 각각에 대한 더 자세한 정보를 검색하기 위해 EKS MCP server의 여러 다른 도구를 사용할 것입니다. 그런 다음 정보 요약을 제공합니다.

<details>
  <summary>샘플 응답을 보려면 확장하세요</summary>

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

훨씬 더 복잡한 작업을 수행해 보겠습니다 - 테스트 Pod를 배포하고 인터넷 연결을 확인합니다:

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

이 복잡한 작업은 Amazon Q CLI의 여러 기능을 보여줍니다:

- 자연어 프롬프트 처리
- 단계별 실행 계획 생성
- MCP server를 통해 제공된 것 중에서 적절한 도구 선택
- 명확한 요약 생성

<details>
  <summary>샘플 응답을 보려면 확장하세요</summary>

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

Q CLI 세션을 종료하려면 다음을 입력하세요:

```text
/quit
```

다음 섹션에서는 클러스터 트러블슈팅을 위해 Amazon Q CLI를 사용하는 방법을 살펴보겠습니다.

