---
title: "Troubleshooting with Amazon Q CLI"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Use Amazon Q CLI along with Amazon EKS MCP server to troubleshoot workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment aiml/q-cli
```

This will make the following changes to your lab environment:

- Deploys a failing pod for the purpose of troubleshooting

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/q-cli/.workshop/terraform).

:::

[Amazon Q Developer’s new command line interface (CLI) agent](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html) has completely transformed the way we approach software development. By bringing the power of an advanced AI assistant directly into our preferred command-line environment, we can now accomplish complex tasks faster than ever before. Q Developer’s natural language understanding and contextual awareness, combined with the CLI agent’s ability to reason and use a wide range of development tools including a set of [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) servers with the tools they offer, could make it an indispensable part of our daily workflow. The support for multi-turn conversations, enable us to collaborate with, and work along side the agent to get more work done, faster.

This section will focus on the following learning objectives.

- Configure Amazon Q CLI in your environment
- Configure MCP server for Amazon EKS for Amazon Q CLI
- Get EKS cluster details using Amazon Q CLI
- Deploy an application to Amazon EKS using Amazon Q CLI
- Troubleshoot workloads on Amazon Elastic Kubernetes Service (EKS) using Amazon Q CLI
