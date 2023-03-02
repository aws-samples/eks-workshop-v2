---
title: In your AWS account
sidebar_position: 30
---

:::danger
Provisioning this workshop environment in your AWS account will create resources and **there will be cost associated with them**. The cleanup section provides a guide to remove them, preventing further charges.
:::

## Provisioning

In this workshop, we'll use Terraform to provision the required infrastructure and get everything up and running. This workshop is tested in us-east-2, us-west-2, and eu-west-1.

### Prerequisites:
 - [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Set up
Use the following instructions to set up the Terraform project.

1. For Terraform to be able to deploy resources in your AWS account, it is recommended to configure your AWS credentials in environment variables or shared configuration/credentials files. Follow the instructions in the [Terraform documentation for the AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-configuration-and-credentials-files) to set up these credentials. In addition, ensure that `AWS_REGION` is set to the region you intend to deploy. If you have multiple profiles in your credentials file, you will also need to set `AWS_PROFILE`.

1. Clone the GitHub repository or download and unzip an archive file.

```bash test=false
$ git clone https://github.com/aws-samples/eks-workshop-v2.git
$ cd eks-workshop-v2
$ git checkout latest
$ cd terraform
```

2. The workshops require Terraform version 1.3.7+. Check your version:

```bash test=false
$ terraform version
```

3. Run the following command to launch Terraform and create the supporting infrastructure.

```bash test=false
$ terraform init
# You can use plan command to preview the resources that will be create if you want
$ terraform apply --auto-approve 
```

:::caution
The Terraform state file (`terraform.tfstate`) is used by Terraform to track the resources that were provisioned which is critical for the cleanup process. If you delete/lose it, you will have to manually delete the resources.
:::

## Cleanup

When you're done with the workshop, to avoid any unexpected costs, you'll be responsible for the cleanup of any resources in your account. This section has the instructions for cleanup.

1. From Cloud9, run the following to clean the environment.

```bash test=false
$ delete-environment
```

2. The following commands will delete the resources you've created with Terraform (using the terraform.tfstate from [Provisioning](#provisioning) above).

```bash test=false
# To delete general add-ons, run the following command:
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
# To delete the descheduler add-on, run the following command:
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
# To delete the core blueprints add-ons, run the following command:
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
# To delete the remaining resources created by Terraform, run the following command:
$ terraform destroy --auto-approve
```

Proceed to the [Accessing the IDE](../ide) section to access your Cloud9 IDE environment.
