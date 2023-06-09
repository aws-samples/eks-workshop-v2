---
title: Exploring the IDE
sidebar_position: 25
---

The provisioned lab environment includes an AWS Cloud9 IDE with the prerequisite tools and environment setup to simplify cluster access and reset of the environment between exercises.

Once you have accessed the IDE, we recommend you use the **+** button and select **New Terminal** to open a new full screen terminal window.

![Open new Cloud9 terminal](./assets/terminal-open.png)

This will open a new tab with a fresh terminal.

![Shows new Cloud9 terminal](./assets/terminal.png)

You may also close the small terminal at the bottom if you wish.

The AWS CLI is already installed and will assume the credentials attached to the Cloud9 IDE:

```bash test=false
$ aws eks list-clusters
```

The `kubectl` utility is also installed and has been pre-configured to authenticate with the cluster you have set up in the previous steps:

```bash test=false
$ kubectl get nodes
```