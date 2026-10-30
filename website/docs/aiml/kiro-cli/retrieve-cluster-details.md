---
title: "Retrieve cluster details"
sidebar_position: 21
---

In this section we will use Kiro CLI along with the AWS-hosted [Amazon EKS MCP server](https://docs.aws.amazon.com/eks/latest/userguide/eks-mcp-introduction.html) to retrieve details of the EKS cluster using natural language commands.

:::info
The `❯` symbol at the beginning of a command line indicates you have an active Kiro CLI session. You can type or paste the prompt text provided in this lab at this prompt. If you don't see the `❯` prompt, restart your Kiro CLI session using the `kiro-cli chat` command.
:::

Let's start by getting details about our EKS cluster. Enter the following prompt:

```text
Summarize the configuration of the eks-workshop EKS cluster.
```

Observe how Kiro CLI processes this natural language command. It would ask your permission to access `use_aws` MCP tool available to it by default. For example:

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

Select `Yes` or `Trust` to allow Kiro to use the selected tool. For this prompt Kiro CLI didn't need to use any tools from the EKS MCP server.

Kiro would run various commands to pull required details and should show an EKS cluster summary generated in Markdown format. Expand the section below to see a sample.

<details>
  <summary>Expand for sample response</summary>

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
As per the basic characteristics of GenAI models, it is possible and normal to see the response you may get from Kiro CLI be different from what is shown in this and other Kiro CLI labs for the given prompts. You may get somewhat different responses for the same prompt if you try them more than once.
:::

Now, let's try a more complex query that requires the EKS MCP server:

```text
List all pods in the carts namespace with their IP addresses along with the host names they are running on.
```

If the EKS MCP server is properly configured, you'll see the following line indicating the use of EKS MCP server tools:

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
Select `Yes` or `Trust` to allow Kiro using this tool.

Kiro CLI will likely use several different tools from the EKS MCP server to list the pods and then retrieve more detailed information for each one. It will then provide a summary of the information.

<details>
  <summary>Expand for sample response</summary>

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

Let's perform an even more complex task - deploying a test pod and checking internet connectivity:

```text
Deploy a test pod in my cluster and check if it can access internet. If the test is successful, remove the test pod. Otherwise, troubleshoot the issue and suggest solutions.
```

Approve Kiro to use required tools to complete this complex task. You should see the following capabilities of Kiro CLI:

- Processing natural language prompts
- Creating step-by-step execution plans
- Selecting appropriate tools from whats been made available through MCP servers
- Generating clear summaries

<details>
  <summary>Expand for sample response</summary>

```text
  Internet connectivity test passed. The test pod successfully reached https://www.google.com and received an HTTP 200 response. The pod has been cleaned up.
  
  Your cluster's pods have working outbound internet access, meaning DNS resolution, NAT gateway (or equivalent), and security group/NACL rules are all functioning correctly.

▸ Credits: 0.40 • Time: 3m 40s

```

</details>

To exit the Kiro CLI session, enter:

```text
/quit
```

In the next section, we'll explore how to use Kiro CLI for cluster troubleshooting.
