---
title: Using Terraform
sidebar_position: 30
---

:::warning
Creating the workshop cluster with Terraform is currently in preview. Please raise any issues encountered in the [GitHub repository](https://github.com/aws-samples/eks-workshop-v2/issues).
:::

This section outlines how to build a cluster for the lab exercises using the [Hashicorp Terraform](https://developer.hashicorp.com/terraform). This is intended to be for learners that are used to working with Terraform infrastructure-as-code.

The `terraform` CLI has been pre-installed in your IDE so we can immediately create the cluster. Let's take a look at the main Terraform configuration files that will be used to build the cluster and its supporting infrastructure.

## Understanding Terraform config files

The `providers.tf` file configures the Terraform providers that will be needed to build the infrastructure. In our case, we use the `aws`, `kubernetes` and `helm` providers:

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

The `main.tf` file sets up some Terraform data sources so we can retrieve the current AWS account and region being used, as well as some default tags:

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

The `vpc.tf` configuration will make sure our VPC infrastructure is created:

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

Finally, the `eks.tf` file specifies our EKS cluster configuration, including a Managed Node Group:

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Creating the workshop environment with Terraform

For the given configuration, `terraform` will create the Workshop environment with the following:

- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Download the Terraform files:

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

Run the following Terraform commands to deploy your workshop environment.

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

This generally takes 20-25 minutes to complete.

## Next Steps

Now that the cluster is ready, head to the [Navigating the labs](/docs/introduction/navigating-labs) section or skip ahead to any module in the workshop with the top navigation bar. Once you're completed with the workshop, follow the steps below to clean-up your environment.

## Cleaning Up

:::warning
The following demonstrates how you will later clean up resources once you have completed your desired lab exercises. These steps will delete all provisioned infrastructure.
:::

Before deleting the Cloud9/VSCode IDE environment we need to clean up the cluster that we set up above.

First use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next delete the cluster with `terraform`:

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```