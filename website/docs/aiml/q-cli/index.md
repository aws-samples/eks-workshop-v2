---
title: "Operating EKS with Amazon Q CLI"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Amazon Q CLI along with Amazon EKS MCP server to manage Amazon EKS clusters."
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/q-cli
```

This will make the following changes to your lab environment:

- Creates a DynamoDB table for Carts application
- Creates a KMS key for the DynamoDB table
- Creates an IAM role and policy to allow the DynamoDB table to use the KMS key
- Configure EKS Pod Identity setup to allow Carts application to access the DynamoDB table

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/q-cli/.workshop/terraform).
:::

[Amazon Q Developer's command line interface (CLI) agent](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html) transforms the software development experience by bringing the power of an advanced AI assistant directly to your command-line environment. The agent leverages natural language understanding and contextual awareness to help you accomplish complex tasks more efficiently. It integrates with a set of [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) servers, including one specifically for Amazon EKS, providing access to powerful development tools. The support for multi-turn conversations enables collaborative interaction with the agent, helping you accomplish more in less time.

In this section, you will learn how to:

- Configure Amazon Q CLI in your environment
- Set up the MCP server for Amazon EKS
- Retrieve EKS cluster details using Amazon Q CLI
- Deploy applications to Amazon EKS using Amazon Q CLI
- Troubleshoot workloads on Amazon EKS using Amazon Q CLI

:::caution Preview
This module is currently in preview, please [report any issues](https://github.com/aws-samples/eks-workshop-v2/issues) encountered.
:::
