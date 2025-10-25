---
title: Using Terraform
sidebar_position: 30
---

:::warning
Creating the workshop cluster with Terraform is currently in preview. Please raise any issues encountered in the [GitHub repository](https://github.com/aws-samples/eks-workshop-v2/issues).
:::

This section outlines how to build a cluster for the lab exercises using [HashiCorp Terraform](https://developer.hashicorp.com/terraform). This is intended for learners who are familiar with using Terraform infrastructure-as-code.

The `terraform` CLI has been pre-installed in your IDE environment, so we can immediately create the cluster. Let's examine the main Terraform configuration files that will be used to build the cluster and its supporting infrastructure.

## Understanding Terraform config files

The `providers.tf` file configures the Terraform providers needed to build the infrastructure. In our case, we use the `aws`, `kubernetes`, and `helm` providers:

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

The `main.tf` file sets up Terraform data sources to retrieve the current AWS account and region being used, as well as some default tags:

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

The `vpc.tf` configuration ensures our VPC infrastructure is created:

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

Finally, the `eks.tf` file specifies our EKS cluster configuration, including a Managed Node Group:

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Creating the workshop environment with Terraform

Based on this configuration, Terraform will create the workshop environment with the following:

- A VPC across three availability zones
- An EKS cluster
- An IAM OIDC provider
- A managed node group named `default`
- VPC CNI configured to use prefix delegation

Download the Terraform files:

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

Run the following Terraform commands to deploy your workshop environment:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

This process generally takes 20-25 minutes to complete.

## Next Steps

Now that the cluster is ready, head to the [Navigating the labs](/docs/introduction/navigating-labs) section or skip ahead to any module in the workshop using the top navigation bar. Once you've completed the workshop, follow the steps below to clean up your environment.

## Cleaning Up (steps once you are done with the Workshop)

:::warning
The following demonstrates how to clean up resources once you are done using the EKS cluster. Completing these steps will prevent further charges to your AWS account.
:::

Before deleting the IDE environment, clean up the cluster that we set up in previous steps.

First, use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next, delete the cluster with `terraform`:

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

You can now proceed to [cleaning](./cleanup.md) up the IDE.
