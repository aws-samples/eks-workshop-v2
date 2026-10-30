---
title: "Introduction"
sidebar_position: 3
---

Traditionally, to use ACK you would install and operate a service controller yourself for each AWS service, for example by deploying its Helm chart and container image into the cluster and then keeping it patched and upgraded over time. Each ACK service controller is packaged into a separate container image published in a public repository. Helm charts and official container images for ACK are available [here](https://gallery.ecr.aws/aws-controllers-k8s).

Instead, this lab uses [Amazon EKS capabilities](https://docs.aws.amazon.com/eks/latest/userguide/capabilities.html) to provide ACK as a fully managed capability. With this approach:

- The ACK controller runs in AWS-managed infrastructure instead of consuming compute in your cluster
- AWS handles installation, patching, upgrades and availability of the controller
- The capability assumes a dedicated IAM capability role, so there is no need to configure IRSA for the controller
- You continue to use the same ACK custom resources and `kubectl` workflow

The ACK capability for Amazon DynamoDB was already enabled for you when you prepared your environment, so there is nothing to install. Let's confirm the capability is active:

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_NAME \
  --capability-name ack-dynamodb \
  --query 'capability.status' --output text
ACTIVE
```

Because the controller is fully managed, no controller deployment runs in your cluster. We'll take a closer look at how it works in the next section.
