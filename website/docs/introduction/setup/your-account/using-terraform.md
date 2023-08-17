---
title: Using Terraform
sidebar_position: 30
---

This section outlines how to build a cluster for the lab exercises using the [Hashicorp Terraform](https://developer.hashicorp.com/terraform). This is intent to be for learners that are used work with Terraform IaC.

The `terraform` CLI has been pre-installed in your Amazon Cloud9 Environment, so we can immediately create the cluster. These are the configuration files that will be used to build the cluster:

versions.tf
```hcl
manifests/../cluster/terraform/versions.tf
```

main.tf
```hcl
manifests/../cluster/terraform/main.tf
```

variables.tf
```hcl
manifests/../cluster/terraform/variables.tf
```

outputs.tf
```hcl
manifests/../cluster/terraform/outputs.tf
```

For the given configuration, `terraform` will create the Workshop environment with the following:
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Download the Terraform file:

```bash test=false
$ mkdir ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/rodrigobersa/eks-workshop-v2/cluster/terraform/cluster/terraform/{main.tf,variables.tf,versions.tf,outputs.tf}
```

Run Terraform commands to deploy your Workshop environment.

```bash test=false
terraform init
terraform apply -auto-approve
```

This generally takes 20-25 minutes to complete. Once the cluster is created run this command to use the cluster for the lab exercises:

```bash test=false
$ use-cluster $EKS_CLUSTER_NAME
```

Now that the cluster is ready, head to the [Getting Started](/docs/introduction/getting-started) module or skip ahead to any module in the workshop with the top navigation bar. Once you're completed with the workshop, follow the steps below to clean-up your environment.

## Cleaning Up

Before deleting the Cloud9 environment we need to clean up the cluster that we set up above.

First use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash test=false
$ delete-environment
```

Next delete the cluster with `terraform`:

```bash test=false
$ cd ~/environment/terraform
$ terraform destroy -auto-approve
```