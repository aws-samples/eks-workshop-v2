---
title: Migrating legacy lab environment
---

On 21st July 2023 the EKS Workshop underwent some major changes regarding how the infrastructure is provisioned. Previously the workshop would rely on Terraform to provision all infrastructure prior to starting, and it was decided to make changes to reduce the number of issues that could occur getting started initially. The workshop infrastructure is now built incrementally, with a simplified initial setup.

If you have a lab environment that was provisioned via the legacy mechanism based on Terraform you will need to migrate to this new provisioning mechanism. The steps below provide a guide to clean up your existing environment.

First, access the Cloud9 IDE and run the following to clean up the sample application running in the cluster. This is necessary to ensure Terraform can clean up the EKS cluster and VPC:

```bash test=false
$ delete-environment
```

Next you should delete the AWS resources that were provisioned by Terraform. From the Git repository you initially cloned (for example on your local machine) run the following commands:

```bash test=false
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
# To delete the descheduler add-on, run the following command:
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
# To delete the core blueprints add-ons, run the following command:
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
# To delete the remaining resources created by Terraform, run the following command:
$ terraform destroy --auto-approve
```

You can now create a new lab environment following the steps [outlined here](/docs/introduction/setup/your-account).
