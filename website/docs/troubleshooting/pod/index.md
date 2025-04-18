---
title: "Pod Issues"
sidebar_position: 70
description: "Troubleshoot common pod issues in Amazon EKS clusters"
sidebar_custom_props: { "module": true }
---

::required-time

In this section, we'll learn how to troubleshoot some of the most common pod issues which prevent the containerized application from running in an Amazon EKS cluster, such as ImagePullBackOff and stuck in ContainerCreating state.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/pod
```

The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:

- Create a ECR repo named retail-sample-app-ui.
- Create a EC2 instance and push retail store sample app image in to the ECR repo from the instance using tag 0.4.0
- Create a new deployment named ui-private in default namespace.
- Create a new deployment named ui-new in default namespace
- Install aws-efs-csi-driver addon in the EKS cluster.
- Create a EFS filesystem and mount targets.
- Introduce an issue to the deployment spec, so we can learn how to troubleshoot this type of issue.
- Introduce an issue to the deployment spec, so we can learn how to troubleshoot these types of issues
- Create a deployment named efs-app backed by a persistent volume claim named efs-claim to leverage EFS as persistent volume, in the default namespace.

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/pod/.workshop/terraform).
:::
