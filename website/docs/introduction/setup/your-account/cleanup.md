---
title: Cleaning up
sidebar_position: 90
---

:::caution

Make sure you have run the respective clean up instructions for the mechanism you used to provision the lab EKS cluster before proceeding.

- [eksctl](./using-eksctl)
- [Terraform](./using-terraform)

:::

This section outlines how to clean up the IDE we've used to run the labs.

Start by opening CloudShell in the region where you deployed the CloudFormation stack:

https://console.aws.amazon.com/cloudshell/home

Then run the following command to delete the CloudFormation stack:

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```
