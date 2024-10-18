---
title: Navigating the labs
sidebar_position: 25
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Let’s review how to navigate this web site and the content provided.

## Structure

The content of this workshop is made up of:

1. Individual lab exercises
2. Supporting content that explains concepts related to the labs

The lab exercises are designed in a way that you can run any modules as a self-contained exercise. Lab exercises will be displayed in the sidebar to the left and are designated by the icon shown here:

![Lab icon example](./assets/lab-icon.webp)

This module contains a single lab named **Getting started** which will be visible on the left side of your screen.

:::caution
You should start each lab from the page indicated by this badge. Starting in the middle of a lab will cause unpredictable behavior.
:::

<Tabs groupId="ide">
<TabItem value="cloud9" label="AWS Cloud9">

Once you have accessed the Cloud9 IDE, we recommend you use the **+** button and select **New Terminal** to open a new full screen terminal window.

![Open new Cloud9 terminal](./assets/terminal-open.webp)

This will open a new tab with a fresh terminal.

![Shows new Cloud9 terminal](./assets/terminal.webp)

You may also close the small terminal at the bottom if you wish.
</TabItem>
<TabItem value="vscode" label="VSCode">

Depending on your browser the first time you copy/paste content in to the VSCode terminal you may be presented with a prompt that looks like this:

![VSCode copy/paste](./assets/vscode-copy-paste.webp)

</TabItem>
</Tabs>

## Terminal commands

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

## Resetting your EKS cluster

In the event that you accidentally configure your cluster in a way that is not functioning you have been provided with a mechanism to reset your EKS cluster as best we can which can be run at any time. Simply run the command `prepare-environment` and wait until it completes. This may take several minutes depending on the state of your cluster when it is run.

## Next Steps

Now that you're familiar with the format of this workshop, head to the [Getting started](/docs/introduction/getting-started) lab or skip ahead to any module in the workshop with the top navigation bar.
