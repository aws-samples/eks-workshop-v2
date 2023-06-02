---
title: Exploring the IDE
sidebar_position: 25
---

The provisioned lab environment includes an AWS Cloud9 IDE with the prerequisite tools and environment setup to simplify cluster access and reset of the environment between exercises.

To access the Cloud9 IDE, log into your [AWS console](https://console.aws.amazon.com/). Search for Cloud9 in the menu bar at the top of the screen:

![Search for the Cloud9 service](./assets/search.png)

When the main Cloud9 screen opens expand the menu on the left side of the screen:

![Access Cloud9 service menu](./assets/menu.png)

There will be a Cloud9 environment named **eks-workshop** available, click the **Open** button to launch the IDE:

![Open the Cloud9 IDE](./assets/environment.png)

:::tip

If you do not see the eks-workshop Cloud9 environment this is because it is owned by another IAM user. [Click here](/misc/cloud9-access.md) to see how to resolve the issue.

:::

Once the IDE has loaded, we recommend you use the **+** button and select **New Terminal** to open a new full screen terminal window.

![Open new Cloud9 terminal](./assets/terminal-open.png)

This will open a new tab with a fresh terminal.

![Shows new Cloud9 terminal](./assets/terminal.png)

You may also close the small terminal at the bottom if you wish.

Your IDE comes pre-configured to access the workshop EKS cluster and also provides a set of tools you will need like the `aws` and `kubectl` CLI tools.