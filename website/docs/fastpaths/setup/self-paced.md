---
title: In your AWS account
sidebar_position: 3
---

import IdeSetup from '../../_partials/setup/ide-setup.mdx';
import IdeCleanup from '../../_partials/setup/ide-cleanup.mdx';

:::danger Warning
Provisioning this workshop environment in your AWS account will create resources and **there will be cost associated with them**. The cleanup section provides a guide to remove them, preventing further charges.
:::

This section outlines how to set up the environment to run the Auto Mode labs in your own AWS account.

## Step 1: Create the IDE Environment

<IdeSetup />

## Step 2: Create the EKS Auto Mode Cluster

:::warning
Creating the workshop cluster with Terraform is currently in preview. Please raise any issues encountered in the [GitHub repository](https://github.com/aws-samples/eks-workshop-v2/issues).
:::

Now that you have an IDE environment, you'll build an EKS Auto Mode cluster for the lab exercises using [HashiCorp Terraform](https://developer.hashicorp.com/terraform).

The `terraform` CLI has been pre-installed in your IDE environment, so we can immediately create the cluster. Let's examine the main Terraform configuration files that will be used to build the cluster and its supporting infrastructure.

## Understanding Terraform config files

The `providers.tf` file configures the Terraform providers needed to build the infrastructure. In our case, we use the `aws` provider and set up data sources to retrieve information about the current AWS account, partition, and available availability zones:

```file hidePath=true
manifests/../cluster/terraform-auto/providers.tf
```

The `main.tf` file sets up the EKS Auto Mode cluster, VPC infrastructure, IAM roles for Pod Identity, and a DynamoDB table for the sample application:

```file hidePath=true
manifests/../cluster/terraform-auto/main.tf
```

## Creating the workshop environment with Terraform

Based on this configuration, Terraform will create the workshop environment with the following:

- A VPC across three availability zones
- An EKS Auto Mode cluster
- IAM roles for Pod Identity (carts service and KEDA)
- A DynamoDB table for the sample application

Download the Terraform files:

```bash
$ mkdir -p ~/environment/terraform-auto; cd ~/environment/terraform-auto
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform-auto/{main.tf,variables.tf,providers.tf}
```

Run the following Terraform commands to deploy your workshop environment:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="auto_cluster_name=$EKS_CLUSTER_NAME-auto" -auto-approve
```

This process generally takes 15-20 minutes to complete.

## Choose Your Learning Path

<div style={{display: 'flex', gap: '2rem', marginTop: '2rem', flexWrap: 'wrap'}}>
  <a href="/docs/fastpaths/developer" style={{textDecoration: 'none', color: 'inherit', flex: '1', minWidth: '280px', maxWidth: '400px'}}>
    <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', height: '100%', cursor: 'pointer'}}>
      <h3 style={{marginTop: 0}}>Developer Essentials</h3>
      <p>Learn essential EKS features for deploying and managing containerized applications.</p>
    </div>
  </a>
  <div style={{border: '2px solid #ddd', borderRadius: '8px', padding: '2rem', flex: '1', minWidth: '280px', maxWidth: '400px', opacity: '0.5'}}>
    <h3 style={{marginTop: 0}}>Operator Essentials</h3>
    <p><em>Coming soon</em></p>
  </div>
</div>

## Cleaning Up

:::warning
The following demonstrates how to clean up resources once you are done using the EKS cluster. Completing these steps will prevent further charges to your AWS account.
:::

### Step 1: Clean up the EKS Cluster

First, use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next, delete the cluster with `terraform`:

```bash
$ cd ~/environment/terraform-auto
$ terraform destroy -var="auto_cluster_name=$EKS_CLUSTER_NAME-auto" -auto-approve
```

### Step 2: Clean up the IDE Environment

<IdeCleanup />
