---
title: Navigating the labs
sidebar_position: 25
---

Let’s review how to navigate this web site and the content provided.

## Structure

The content of this workshop is made up of:

1. Individual lab exercises
2. Supporting content that explains concepts related to the labs

The lab exercises are designed in a way that you can run any modules as a self-container exercise. Lab exercises will be displayed in the sidebar to the left and are designated by the icon shown here:

![Lab icon example](./assets/lab-icon.png)

This module contains a single lab named **Getting started** which will be visible on the left side of your screen.

:::caution
You should start each lab from the page indicated by this badge. Starting in the middle of a lab will cause unpredictable behavior.
:::

## Terminal commands

Most of the interaction you will do in this workshop will be done with terminal commands, which you can either manually type or copy/paste to the Cloud9 IDE terminal. You will see this terminal commands displayed like this:

```bash test=false
$ echo "This is an example command"
```

Hover your mouse over `echo "This is an example command"` and click to copy that command to your clipboard.

You will also come across commands with sample output like this:

```bash test=false
$ kubectl get nodes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-104.us-west-2.compute.internal   Ready    <none>   6h      v1.23.9-eks-ba74326
ip-10-42-10-210.us-west-2.compute.internal   Ready    <none>   6h      v1.23.9-eks-ba74326
ip-10-42-11-198.us-west-2.compute.internal   Ready    <none>   6h      v1.23.9-eks-ba74326
```

Using the 'click to copy' function will only copy the command and ignore the sample output.

Another pattern used in the content is presenting several commands in a single terminal:

```bash test=false
$ kubectl get pods
No resources found in default namespace.
$ kubectl get nodes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-104.us-west-2.compute.internal   Ready    <none>   6h2m    v1.23.9-eks-ba74326
ip-10-42-10-210.us-west-2.compute.internal   Ready    <none>   22h     v1.23.9-eks-ba74326
ip-10-42-11-198.us-west-2.compute.internal   Ready    <none>   6h19m   v1.23.9-eks-ba74326
```

In this case you can either copy each command individually or copy all of the commands using the clipboard icon in the top right of the terminal window. Give it a shot!

## Resetting your EKS cluster

In the event that you accidentally configure your cluster in a way that is not functioning you have been provided with a mechanism to reset your EKS cluster as best we can which can be run at any time. Simply run the command `reset-environment` and wait until it completes. This may take several minutes depending on the state of your cluster when it is run.
