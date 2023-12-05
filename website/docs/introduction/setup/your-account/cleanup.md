---
title: Cleaning up
sidebar_position: 90
---

:::caution

Make sure you have run the respective clean up instructions for the mechanism you used to provision the lab EKS cluster before proceeding.

* [eksctl](./using-eksctl#cleaning-up)
* [Terraform](./using-terraform#cleaning-up)

:::

This section outlines how to clean up the Cloud9 IDE we've used to run the labs.

Similar to how we created the Cloud9 instance, start by opening CloudShell:

https://console.aws.amazon.com/cloudshell/home

Then run the following command to delete the CloudFormation stack:

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```