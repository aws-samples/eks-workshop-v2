---
title: Navigating the Labs
sidebar_position: 30
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Let’s review how to navigate this website and the content provided.

## Structure

The content of this workshop is made up of:

1. Individual lab exercises
2. Supporting content that explains concepts related to the labs

The lab exercises are designed in a way that you can run any modules as a self-contained exercise. Lab exercises will be displayed in the sidebar to the left and are designated by the `LAB` icon.

## Opening the IDE

If you haven't done so yet, you can open the IDE from the *Event outputs* section at the bottom of the start page.

 ![Event Outputs copy/paste](/img/fastpaths/ide-open.png)

## Prepare Environment

The `prepare-environment` tool helps you set up and configure your lab environment for each section. Simply run:

```
$ prepare-environment $MODULE_NAME
```

### Basic Usage Patterns
```
$ prepare-environment $MODULE_NAME/$LAB
```

**Examples**
```
# For the getting started lab
$ prepare-environment introduction/getting-started

# For Karpenter autoscaling
$ prepare-environment autoscaling/compute/karpenter

# For storage with EBS
$ prepare-environment fundamentals/storage/ebs

# For networking security groups
$ prepare-environment networking/securitygroups-for-pods
```

:::caution
You should start each lab from the page indicated by "BEFORE YOU START" badge. Starting in the middle of a lab will cause unpredictable behavior.
:::

## Resetting Your Cluster (Modular Section Only)

In the event that you accidentally configure your cluster or module in a way that is not functioning you have been provided with a mechanism to reset your EKS cluster as best we can which can be run at any time. Simply run the command prepare-environment and wait until it completes. This may take several minutes depending on the state of your cluster when it is run.

```bash
$ prepare-environment
```

## Tips

### Copy/Paste Permission
Depending on your browser the first time you copy/paste content in to the VSCode terminal you may be presented with a prompt that looks like this:

![VSCode copy/paste](/docs/introduction/vscode-copy-paste.webp)
### Terminal commands

Most of the interaction you will do in this workshop will be done with terminal commands, which you can either manually type or copy/paste to the IDE terminal. You will see this terminal commands displayed like this:

```bash test=false
$ echo "This is an example command"
```

Hover your mouse over `echo "This is an example command"` and click to copy that command to your clipboard.

You will also come across commands with sample output like this:

```bash test=false
$ date
Fri Aug 30 12:25:58 MDT 2024
```

Using the 'click to copy' function will only copy the command and ignore the sample output.

Another pattern used in the content is presenting several commands in a single terminal:

```bash test=false
$ echo "This is an example command"
This is an example command
$ date
Fri Aug 30 12:26:58 MDT 2024
```

In this case you can either copy each command individually or copy all of the commands using the clipboard icon in the top right of the terminal window. Give it a shot!

## Next Steps

Now that you're familiar with the format of this workshop, head to the [Application Overview](/docs/introduction/application-overview) to learn about the sample application, then proceed to [Getting Started](/docs/introduction/getting-started) lab or skip ahead to any module in the workshop with the top navigation bar.
