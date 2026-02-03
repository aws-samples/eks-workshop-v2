---
title: "Retrieve cluster details"
sidebar_position: 21
---

In this section we will use Kiro CLI along with the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to retrieve details of the EKS cluster using natural language commands.

:::info
The `>` symbol at the beginning of a command line indicates you have an active Kiro CLI session. You can type or paste the prompt text provided in this lab at this prompt. If you don't see the `>` prompt, restart your Kiro CLI session using the `kiro-cli chat` command.
:::

Let's start by getting details about our EKS cluster. Enter the following prompt:

```text
Summarize the configuration of the eks-workshop EKS cluster.
```

Observe how Kiro CLI processes this natural language command. You'll notice it executes various `aws` CLI commands, indicated by the caption `Using tool: use_aws`. For example:

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

For this prompt Kiro CLI didn't need to use any tools from the EKS MCP server.

You should see an EKS cluster summary generated in Markdown format. Expand the section below to see a sample.

<details>
  <summary>Expand for sample response</summary>

```text
Here's a summary of the eks-workshop EKS cluster configuration:

Basic Information:
- Name: eks-workshop
- Version: 1.33
- Status: ACTIVE
- Created: February 2, 2026
- Platform Version: eks.27
- Region: us-west-2

Networking:
- VPC: vpc-0f61f95f5b8afcec2
- Subnets: 6 subnets across availability zones
- Service IPv4 CIDR: 172.16.0.0/16
- Endpoint Access: Both public and private enabled
- Public Access: Open to 0.0.0.0/0
- Elastic Load Balancing: Disabled

Remote Network Configuration (Hybrid Nodes):
- Remote Node Networks: 10.52.0.0/16
- Remote Pod Networks: 10.53.0.0/16

Security:
- Cluster Security Group: sg-0cb155bc445c97558
- Additional Security Group: sg-0f74307591ebddb4d
- IAM Role: eksctl-eks-workshop-cluster-ServiceRole-UkyEe5uUibmE
- Authentication Mode: API_AND_CONFIG_MAP
- OIDC Provider: Enabled

Logging:
- All control plane logs (api, audit, authenticator, controllerManager, scheduler): Disabled

Other Settings:
- Control Plane Tier: Standard
- Deletion Protection: Disabled
- Support Type: Extended
- Created by: eksctl (version 0.215.0)

The cluster is configured with hybrid node support, allowing remote nodes and pods from on-premises or other networks to connect to the cluster.
```

</details>

:::tip
As per the basic characteristics of GenAI models, it is possible and normal to see the response you may get from Kiro CLI be different from what is shown in this and other Kiro CLI labs for the given prompts. You may get somewhat different responses for the same prompt if you try them more than once.
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
The first time you use an MCP server tool, Kiro CLI will ask for permission:

```text
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:
```

You can press `t` and then `Enter` to trust this tool for the session, as it performs read-only operations.
:::

Kiro CLI will likely use several different tools from the EKS MCP server to list the pods and then retrieve more detailed information for each one. It will then provide a summary of the information.

<details>
  <summary>Expand for sample response</summary>

```text
Here are the pods in the carts namespace with their IP addresses and host names:

| Pod Name | Pod IP | Host Name |
|----------|--------|-----------|
| carts-dynamodb-995f7768c-tvshj | 10.42.96.16 | ip-10-42-114-20.us-west-2.compute.internal |
| carts-68d496fff8-jjt8z | 10.42.96.21 | ip-10-42-114-20.us-west-2.compute.internal |

Both pods are running on the same node (ip-10-42-114-20.us-west-2.compute.internal).
```

</details>

Let's perform an even more complex task - deploying a test pod and checking internet connectivity:

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

This complex task demonstrates several capabilities of Kiro CLI:

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

To exit the Kiro CLI session, enter:

```text
/quit
```

In the next section, we'll explore how to use Kiro CLI for cluster troubleshooting.
