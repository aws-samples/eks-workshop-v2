---
title: In your AWS account
sidebar_position: 30
---

:::danger Warning
Provisioning this workshop environment in your AWS account will create resources and **there will be cost associated with them**. The cleanup section provides a guide to remove them, preventing further charges.
:::

This section outlines how to set up the environment to run the labs in your own AWS account.

The first step is to create an IDE with the provided CloudFormation template. Download the template to your machine with [this link](https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/lab/cfn/eks-workshop-ide-cfn.yaml). Next deploy then template either using the AWS console or the command below:

```bash test=false
$ aws cloudformation deploy --stack-name eks-workshop-ide \
    --template-file <path to eks-workshop-ide-cfn.yaml> \
    --capabilities CAPABILITY_NAMED_IAM
```

You can access the Cloud9 IDE created by using [these instructions](../../ide.md).

:::info

All subsequent steps should be run in the Cloud9 instance.

:::

The next step is to create an EKS cluster to perform the lab exercises in. Please follow one of the guides below to provision a cluster that meets the requirements for these labs:
- **(Recommended)** [eksctl](./using-eksctl.md)
- (Coming soon!) Terraform 
- (Coming soon!) CDK