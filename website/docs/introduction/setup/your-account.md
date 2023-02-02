---
title: In your AWS account
sidebar_position: 30
---

## Provisioning

The workshop is using terraform to provision the required infrastructure. The following instructions will allow you to get this up and running:

Prerequisites:
 - terraform (We need 1.2.x): [Installation instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

The following instructions will allow you to run the required Terraform project:

### Clone repo from github or download && unzip from github"
```bash
$ git clone https://github.com/aws-samples/eks-workshop-v2.git
$ cd eks-workshop-v2/terraform
```
### Confirm version is 1.2.x
```bash
$ terraform version
```
### Launch terraform to create supporting infrastructure
```bash
$ terraform init
$ terraform apply --auto-approve # You can use plan command to preview the resources that will be create if you want
```

:::caution
The terraform state file (terraform.tfstate) is used to know what was provisioned and is used in the cleanup process. If you delete/lose it, you will have to manually delete them.
:::

## Cleanup

Since you will be handling the cleanup of the resources yourself in this case. The following commands are used to destroy via Terraform.

### Deleting general addons...
```bash
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
```

### Deleting descheduler addon...
```bash
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
```

### Deleting core blueprints addons...
```bash
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
```

### Deleting everything else...
```bash
$ terraform destroy --auto-approve
```