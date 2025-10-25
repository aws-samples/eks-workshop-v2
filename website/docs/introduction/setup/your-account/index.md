---
title: In your AWS account
sidebar_position: 30
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import IdeSetup from '../../../_partials/setup/ide-setup.mdx';

:::danger Warning
Provisioning this workshop environment in your AWS account will create resources and **there will be cost associated with them**. The cleanup section provides a guide to remove them, preventing further charges.
:::

This section outlines how to set up the environment to run the labs in your own AWS account.

<IdeSetup />

The next step is to create an EKS cluster to perform the lab exercises in.

## Traditional Cluster (Choose Your Own Adventure)

For the traditional learning path, follow one of these guides:

- **(Recommended)** [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)

After setup, **[explore workshop modules →](/docs/fundamentals)**

## Auto Mode Cluster (Developer Fast Path) {#auto-mode}

For the Developer Fast Path, create an Auto Mode cluster:

```bash
cd ~/environment/eks-workshop
export EKS_CLUSTER_NAME=eks-workshop
./hack/create-infrastructure.sh
```

This creates an Auto Mode cluster (`eks-workshop-auto`) with all required resources. Takes ~15-20 minutes.

Verify the cluster:

```bash
export EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME}-auto"
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
kubectl get nodes
```

After setup, **[start the Developer Fast Path →](/docs/fastpaths/developer)**
