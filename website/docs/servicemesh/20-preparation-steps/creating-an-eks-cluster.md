---
title: Creating an EKS cluster with EKS Blueprints
sidebar_position: 20
---

Clone the EKS blueprints for Terraform repo
```bash
$ git clone https://github.com/aws-ia/terraform-aws-eks-blueprints.git
```

In the EKS Blueprints, there are many EKS Blueprints based example modules that you can utilize any of them to build an EKS cluster. Each example for a different purpose. Pick any example that best fits your situation, or even create your own module, if you wish. This module will be the root module that will reference EKS-Blueprints sub-modules.

In this instance, we'll utilize the module example `eks-cluster-with-new-vpc`. 
```bash
$ cd terraform-aws-eks-blueprints/examples/eks-cluster-with-new-vpc
```

Open the main.tf file for editing, and under `locals`, change the `region` to the region you want to deploy your EKS cluster in, and the `vpc-cidr` you want to use ro host this EKS cluster. In our case, the region is **us-east-1** and vpc_cidr is **10.0.0.0/16**. 

```yaml
locals {
  name = basename(path.cwd)
  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, local.name)
  region       = "us-east-1"

  vpc_cidr = "10.10.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}
```

After you've saved your changes, now, you're ready to deploy your EKS cluster into your AWS account with the enabled addons specified under the module `eks_blueprints_kubernetes_addons` by simply having those addons listed with the value `true`. And you can uninstall any of those addons, by simple changing this value to false, or comment the line of it.

Initite this root module
```bash
$ terraform init
```

Assuming inititing the module went well, now you can check what resources would be provisioned
```bash
$ terraform plan
```

If you are all good with it, then go ahead and apply it to your environment. 

```bash
$ terraform apply
```

It may take up to 20 minutes or so to get your cluster up and running with all of the included addons.

> **_Troubelshooting_Note:_**  
Change the value of *enabled_kubekost* to `false`, in case you faced a timeout error creating the cluster with.


The output of the apply command would end with `Outputs` section that includes the configure_kubectl value that have the command you must copy and run into your terminal to set the kubeconfig credentials needed to start working with this cluster you just provisioned. 

```shell
...
Outputs:

configure_kubectl = "aws eks --region us-east-1 update-kubeconfig --name eks-cluster-with-new-vpc"
eks_cluster_id = "eks-cluster-with-new-vpc"
...
```

```bash
$ aws eks --region us-east-1 update-kubeconfig --name eks-cluster-with-new-vpc
```

