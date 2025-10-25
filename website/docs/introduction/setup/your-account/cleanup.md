---
title: Cleaning up
sidebar_position: 90
---

import IdeCleanup from '../../../_partials/setup/ide-cleanup.mdx';

:::caution

Make sure you have run the respective clean up instructions for the mechanism you used to provision the lab EKS cluster before proceeding:

- [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)

:::

This section outlines how to clean up the IDE we've used to run the labs.

<IdeCleanup />

Alternatively, you can use CloudShell to delete the stack:

<ConsoleButton url="https://console.aws.amazon.com/cloudshell/home" service="console" label="Open CloudShell"/>

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```

Once the stack is deleted, all resources associated with the IDE will be removed from your AWS account, preventing further charges.
