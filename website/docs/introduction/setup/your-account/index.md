---
title: In your AWS account
sidebar_position: 30
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

:::danger Warning
Provisioning this workshop environment in your AWS account will create resources and **there will be cost associated with them**. The cleanup section provides a guide to remove them, preventing further charges.
:::

This section outlines how to set up the environment to run the labs in your own AWS account.

The first step is to create an IDE with the provided CloudFormation templates. Use the AWS CloudFormation quick-create links below to launch the desired template in the appropriate AWS region.

| Region           | Link                                                                                                                                                                                                                                                                                                                              |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [Launch](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `eu-west-1`      | [Launch](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `ap-southeast-1` | [Launch](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF) |

These instructions have been tested in the AWS regions listed above and are not guaranteed to work in others without modification.

:::warning

The nature of the workshop material means that the IDE EC2 instance requires broad IAM permissions in your account, for example creating IAM roles. Before continuing please review the IAM permissions that will be provided to the IDE instance in the CloudFormation template.

We are continuously working to optimize the IAM permissions. Please raise a [GitHub issue](https://github.com/aws-samples/eks-workshop-v2/issues) with any suggestions for improvement.

:::

Scroll to the bottom of the screen and acknowledge the IAM notice:

![acknowledge IAM](./assets/acknowledge-iam.webp)

Then click the **Create stack** button:

![Create Stack](./assets/create-stack.webp)

The CloudFormation stack will take roughly 5 minutes to deploy, and once completed you can retrieve information required to continue from the **Outputs** tab:

![cloudformation outputs](./assets/vscode-outputs.webp)

The `IdeUrl` output contains the URL to enter in your browser to access the IDE. The `IdePasswordSecret` contains a link to an AWS Secrets Manager secret that contains a generated password for the IDE.

To retrieve the password open the `IdePasswordSecret` URL and click the **Retrieve** button:

![secretsmanager retrieve](./assets/vscode-password-retrieve.webp)

The password will then be available for you to copy:

![password in Secrets Manager](./assets/vscode-password-visible.webp)

Open the IDE URL provided and you will be prompted for the password:

![IDE password prompt](./assets/vscode-password.webp)

After submitting your password you will be presented with the initial IDE screen:

![IDE initial screen](./assets/vscode-splash.webp)

The next step is to create an EKS cluster to perform the lab exercises in. Please follow one of the guides below to provision a cluster that meets the requirements for these labs:

- **(Recommended)** [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)
- (Coming soon!) CDK
