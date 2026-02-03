---
title: "Retrieve cluster details"
sidebar_position: 21
---

In this section we will use Amazon Q CLI along with the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to retrieve details of the EKS cluster using natural language commands.

:::info
The `>` symbol at the beginning of a command line indicates you have an active Amazon Q CLI session. You can type or paste the prompt text provided in this lab at this prompt. If you don't see the `>` prompt, restart your Amazon Q CLI session using the `q chat` command.
:::

Let's start by getting details about our EKS cluster. Enter the following prompt:

```text
Summarize the configuration of the eks-workshop EKS cluster
```

Observe how Amazon Q CLI processes this natural language command. You'll notice it executes various `aws` CLI commands, indicated by the caption `Using tool: use_aws`. For example:

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

For this prompt Amazon Q CLI didn't need to use any tools from the EKS MCP server.

You should see an EKS cluster summary generated in Markdown format. Expand the section below to see a sample.

<details>
  <summary>Expand for sample response</summary>

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
As per the basic characteristics of GenAI models, it is possible and normal to see the response you may get from Q CLI be different from what is shown in this and other Q CLI labs for the given prompts. You may get somewhat different responses for the same prompt if you try them more than once.
:::

Now, let's try a more complex query that requires the EKS MCP server:

```text
List all pods in the carts namespace with their IP addresses along with the host names they are running on.
```

If the EKS MCP server is properly configured, you'll see the following line indicating the use of EKS MCP server tools:

```text
🛠️ Using tool: list_k8s_resources from mcp server awslabseks_mcp_server
```

:::note
The first time you use an MCP server tool, Amazon Q CLI will ask for permission:

```text
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:
```

You can press `t` and then `Enter` to trust this tool for the session, as it performs read-only operations.
:::

Q CLI will likely use several different tools from the EKS MCP server to list the pods and then retrieve more detailed information for each one. It will then provide a summary of the information.

<details>
  <summary>Expand for sample response</summary>

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

Let's perform an even more complex task - deploying a test pod and checking internet connectivity:

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

This complex task demonstrates several capabilities of Amazon Q CLI:

- Processing natural language prompts
- Creating step-by-step execution plans
- Selecting appropriate tools from whats been made available through MCP servers
- Generating clear summaries

<details>
  <summary>Expand for sample response</summary>

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

To exit the Q CLI session, enter:

```text
/quit
```

In the next section, we'll explore how to use Amazon Q CLI for cluster troubleshooting.
