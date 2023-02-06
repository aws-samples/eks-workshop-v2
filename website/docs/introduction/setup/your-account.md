---
title: In your AWS account
sidebar_position: 30
---

## Provisioning

In this workshop, we'll use Terraform to provision the required infrastructure and get everything up and running. If you provision this in your account, **there will be cost associated with them**. The cleanup section will guide you to remove them to prevent future charges.

### Prerequisites:
 - [Install terraform 1.2.x](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Set up
Use the following instructions to set up the Terraform project.

1. Clone the GitHub repository or download and unzip an archive file.

```bash test=false
$ git clone https://github.com/aws-samples/eks-workshop-v2.git
$ cd eks-workshop-v2/terraform
```
2. Check that your terraform version is 1.2.x.

```bash test=false
$ terraform version
```
3. Run the following command to launch Terraform and create the supporting infrastructure.

```bash test=false
$ terraform init
$ terraform apply --auto-approve # You can use plan command to preview the resources that will be create if you want
```

:::caution
The terraform state file (terraform.tfstate) is used to know what was provisioned and is used in the cleanup process. If you delete/lose it, you will have to manually delete them.
:::

## Cleanup

In your account, you'll be handling the cleanup of any resources you create. You can use the following commands to delete the resources you've created with Terraform.

1. To delete general add-ons, run the following command:

```bash test=false
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
```

2. To delete the descheduler add-on, run the following command:
```bash test=false
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
```

3. To delete the core blueprints add-ons, run the following command:
```bash test=false
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
```

4. To delete the remaining resources created by Terraform, run the following command:
```bash test=false
$ terraform destroy --auto-approve
```