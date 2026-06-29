---
title: "Setup"
sidebar_position: 20
---

In this section we will configure Kiro CLI along with the [AWS-Hosted MCP server for Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/eks-mcp-introduction.html) to work with the EKS cluster using natural language commands.

:::info
Kiro CLI leverages generative AI capabilities for common development and operations tasks. Its capabilities can be enhanced by adding purpose-built MCP servers for specialized knowledge. We'll use the AWS-Hosted Amazon EKS MCP server with Kiro CLI in this section. You can find a catalog of AWS-provided MCP servers [here](https://awslabs.github.io/mcp/), which can be used with Kiro CLI in a similar way.
:::

## Install Kiro CLI

First, install the `uv` package manager (required to run MCP server proxies):

```bash
$ curl -LsSf https://astral.sh/uv/install.sh | sh
$ source $HOME/.local/bin/env
```

Next, install Kiro CLI using the official installer:

```bash
$ curl -fsSL https://cli.kiro.dev/install | bash
```

Verify the installation:

```bash test=false
$ kiro-cli --version
```

## MCP Server Configuration

The `prepare-environment` step has already configured Kiro CLI with the AWS-Hosted EKS MCP server and the AWS MCP server. The configuration is located at `~/.kiro/settings/mcp.json` and connects to the managed MCP endpoints in your region — no local server installation required.

:::info
The AWS-Hosted MCP server uses `mcp-proxy-for-aws` to proxy requests to the managed AWS endpoints (`eks-mcp.<region>.api.aws`). Authentication is handled via your existing AWS credentials and IAM policies. This eliminates the need to manage local MCP server versions.
:::

## Authenticate Kiro CLI

To use Kiro CLI, you need to authenticate. The `prepare-environment` step provisioned an IAM Identity Center user for you with a Kiro Pro+ license.

Retrieve your Kiro credentials from the environment variables:

```bash
$ echo "Start URL: $KIRO_START_URL"
$ echo "Username:  $KIRO_USER"
$ echo "Password:  $KIRO_PASSWORD"
$ echo "Region:    $KIRO_REGION"
```

:::tip
Make note of these credentials — you'll need them in the next step.
:::

Now authenticate Kiro CLI:

```bash test=false
$ kiro-cli login --use-device-flow
? Select login method >
> Use with Builder ID
  Use with Google
  Use with GitHub
  Use with Your Organization
```

Select **"Use with Your Organization"** using the arrow keys and press Enter.

When prompted for the **Start URL**, enter the value from `$KIRO_START_URL` and press Enter.

When prompted for the **Region**, enter the value from `$KIRO_REGION` (e.g., `us-west-2`) and press Enter.

The CLI will display a confirmation code and a URL to open in your browser:

```text
Confirm the following code in the browser
Code: XXXX-XXXX

Open this URL: https://...
Logging in...
```

Open the URL in your browser and sign in with:
- **Username:** the value from `$KIRO_USER` (typically `kiro`)
- **Password:** the value from `$KIRO_PASSWORD`

:::info
On first login, you will be asked to set a new password. Choose any password you prefer and click "Set new password" to continue.
:::

After signing in, confirm the code matches the one displayed in your terminal, then click **"Confirm and continue"** followed by **"Allow access"**.

Return to your terminal — you should see:

```text
Device authorized

Logged in successfully
```

Verify authentication:

```bash test=false
$ kiro-cli whoami
```

You should see output confirming your IAM Identity Center authentication and profile assignment.

## Verify MCP Server

Let's verify that the MCP servers are available by initializing a session:

```bash test=false
$ kiro-cli chat
```

To see the tools offered by the EKS MCP server, run:

```text
/tools
```

You should see output similar to this:

![list-mcp-tools](/docs/aiml/kiro-cli/list-mcp-tools.jpg)

The output shows:

1. The default large language model (LLM) selected by Kiro CLI (can be changed using the `/model` command)
2. The list of tools offered by the EKS MCP server and AWS MCP server
3. The default permissions Kiro CLI has for each tool

:::info
When a tool is marked as `not trusted`, Kiro CLI will request your permission before using it. This is a safety measure, particularly for tools that can create, update, or delete resources. Since LLMs can make mistakes, this gives you an opportunity to review potentially disruptive actions before they're executed.
:::

To exit the session:

```text
/quit
```

In the next section, we'll use Kiro CLI to retrieve information about our EKS cluster.
