---
title: "Add-ons"
sidebar_position: 20
---

EKS add-ons allows you to configure, deploy, and update the operational software, or add-ons, that provide key functionality to support your Kubernetes applications. These add-ons include critical tools for cluster networking like the Amazon VPC CNI, as well as operational software for observability, management, scaling, and security. An add-on is basically a software that provides supporting operational capabilities to Kubernetes applications, but is not specific to the application.

**[Amazon EKS add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)** provide installation and management of a curated set of add-ons for Amazon EKS clusters. All Amazon EKS add-ons include the latest security patches, bug fixes, and are validated by AWS to work with Amazon EKS. Amazon EKS add-ons allow you to consistently ensure that your Amazon EKS clusters are secure and stable and reduce the amount of work that you need to do in order to install, configure, and update add-ons.

You can add, update, or delete Amazon EKS add-ons using the Amazon EKS API, AWS Management Console, AWS CLI, and eksctl. You can also [create Amazon EKS add-ons](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/amazon-eks-addons/) , The Amazon EKS add-on implementation is generic and can be used to deploy any add-on supported by the EKS API; either native EKS addons or third party add-ons supplied via the AWS Marketplace.

If you navigate to the **Add-ons** tab you can search for add-ons already installed.

![Insights](/img/resource-view/find-add-ons.jpg)

or 'Get more add-ons' to choose additional add-ons or search AWS MarketPlace add-ons to enhance your cluster.

![Insights](/img/resource-view/select-add-ons.jpg)
