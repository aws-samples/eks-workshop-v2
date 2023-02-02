---
title: In your AWS account
sidebar_position: 30
---

The workshop is using terraform to provision the required infrastructure. The following instructions will allow you to get this up and running:

Prerequisites:
 - terraform (We need 1.2.x): [Installation instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

 ```bash
# Clone repo from github or download && unzip from github
$ git clone https://github.com/aws-samples/eks-workshop-v2.git
$ cd eks-workshop-v2/terraform

# Confirm version is 1.2.x
$ terraform version

# Launch terraform to create supporting infrastructure
$ terraform init

$ terraform apply --auto-approve # You can use plan command to preview the resources that will be create if you want
```
:::Caution
The terraform state file (terraform.tfstate) is used to know what was provisioned and is used in the cleanup process. If you delete/lose it, you will have to manually delete them.
:::

# Cleanup

Since you will be handling the cleanup of the resources yourself in this case. The following commands are used to destroy via Terraform.

```bash
$ cd terraform
$ echo "Deleting general addons..."
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve

$ echo "Deleting descheduler addon..."
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve

$ echo "Deleting core blueprints addons..."
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve

$ echo "Deleting everything else..."
$ terraform destroy --auto-approve
```
