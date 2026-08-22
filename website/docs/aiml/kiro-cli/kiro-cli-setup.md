---
title: "Setup"
sidebar_position: 20
---

In this section we will configure Kiro CLI along with the AWS-hosted [Amazon EKS MCP server](https://docs.aws.amazon.com/eks/latest/userguide/eks-mcp-introduction.html) to work with the EKS cluster using natural language commands.

:::info
The fully managed Amazon EKS MCP server is hosted by AWS — there's no local server to install or maintain. Kiro CLI connects to it through a lightweight client-side proxy (`mcp-proxy-for-aws`) that signs requests with your AWS credentials using [SigV4](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv.html). The Amazon EKS MCP server is in **preview** and subject to change.
:::

:::info
Kiro CLI leverages generative AI capabilities for common development and operations tasks. Its capabilities can be enhanced by adding purpose-built MCP servers for specialized knowledge. In this section we configure three servers: the hosted **Amazon EKS MCP server** (`eks-mcp`) for EKS and Kubernetes operations, the hosted **AWS API MCP server** (`aws-mcp`) for broader AWS resource access, and the **AWS Documentation MCP server** for looking up AWS documentation. You can find a catalog of AWS-provided MCP servers [here](https://awslabs.github.io/mcp/), which can be used with Kiro CLI in a similar way.
:::

First, download the Kiro CLI release for your operating system and CPU architecture:

```bash
$ ARCH=$(arch)
$ mkdir $HOME/tmp
$ curl --proto '=https' --tlsv1.2 \
  -sSf https://desktop-release.q.us-east-1.amazonaws.com/2.10.0/kirocli-${ARCH}-linux.zip \
  -o $HOME/tmp/kirocli.zip
```

Install Kiro CLI:

```bash
$ unzip $HOME/tmp/kirocli.zip -d $HOME/tmp
$ bash $HOME/tmp/kirocli/install.sh --no-confirm
```

Verify the installation:

```bash
$ kiro-cli version
kiro-cli 2.10.0
```

Next, we'll configure Kiro CLI with the hosted MCP servers. Here is the configuration we'll use:

```file
manifests/modules/aiml/kiro-cli/setup/eks-mcp.json
```

The `eks-mcp` and `aws-mcp` entries run the `mcp-proxy-for-aws` proxy via `uvx`, which forwards requests to the hosted endpoints (`https://eks-mcp.<region>.api.aws/mcp` and `https://aws-mcp.<region>.api.aws/mcp`) and signs them with your AWS credentials. The `${AWS_REGION}` placeholders are replaced with your lab's active region when we write the file below.

:::info
`uvx` is a Python package runner tool that comes with the uv package manager. It runs Python packages directly without installing them globally. Then, it downloads and executes Python tools in isolated environments similar to `npx` for Node.js, but for Python packages.
:::

Write the MCP configuration to `~/.kiro/settings/mcp.json`, substituting your region, and install the required `uv`/`uvx` tool:

```bash
$ mkdir -p $HOME/.kiro/settings
$ envsubst '$AWS_REGION' \
  < ~/environment/eks-workshop/modules/aiml/kiro-cli/setup/eks-mcp.json \
  > $HOME/.kiro/settings/mcp.json
$ curl -LsSf https://astral.sh/uv/0.11.26/install.sh | sh
```

:::info
The hosted MCP servers authenticate as your workshop IDE role using [AWS SigV4](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv.html). The required `eks-mcp` and `aws-mcp` IAM permissions are already provisioned for your IDE role, and write (privileged) tools work because the `eks-workshop` cluster's API endpoint is publicly accessible. No `aws eks update-kubeconfig` or extra credential setup is needed.
:::

To use Kiro CLI, you'll need to authenticate using either an AWS Builder ID or a Pro license subscription.

:::tip
You can create a free AWS Builder ID by following [these instructions](https://docs.aws.amazon.com/signin/latest/userguide/create-aws_builder_id.html). This Builder ID can also be used for personal use of Kiro CLI.
:::

```bash test=false
$ kiro-cli login --use-device-flow
? Select login method >
> Use with Builder ID
  Use with Google
  Use with GitHub
  Use with Your Organization
```

Select your preferred login method and follow the prompts to login. If you don't already have a Kiro account, you may create a free-trial account using either your Google or GitHub account. You'll need to open a given URL to use link your Google or GitHub account.

:::tip
A Kiro free-trial account should give you 50 Kiro credits to begin with. This lab may only need less than 5 credits. So, you may use that account even outside this workshop to continue your Kiro trial for other projects. You may check your used credits using `/usage` command inside a kiro-cli session. No payment details will be required to create a Kiro free-trial account. 
:::

Let's verify that the MCP server is available by initializing a session:

```bash test=false
$ kiro-cli chat
```

To see the tools offered by the configured MCP servers, run:

```text
/tools
```
You should see output similar to this:

![list-mcp-tools](/img/aiml/kiro-cli/list-mcp-tools.jpg)

The output shows:

1. The space where you can run Kiro commands like `/tools`. You should see all such commands when you type `/`. Learn more about Kiro commands [here](https://kiro.dev/docs/cli/reference/slash-commands/#available-commands).
2. The list of tools offered by the configured MCP servers (`eks-mcp`, `aws-mcp`, and the AWS Documentation server)

:::info
When a tool is marked as `approval required`, Kiro CLI will request your permission before using it. This is a safety measure, particularly for tools that can create, update, or delete resources. Since LLMs can make mistakes, this gives you an opportunity to review potentially disruptive actions before they're executed.
:::

You can follow the same procedure to add other [MCP servers from AWS Labs](https://awslabs.github.io/mcp/) for additional capabilities. For this lab, we'll use the hosted `eks-mcp` and `aws-mcp` servers along with the AWS Documentation server we've configured.

In the next section, we'll use Kiro CLI to retrieve information about our EKS cluster.
