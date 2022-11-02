---
title: "Kubecost and Amazon Managed Service for Prometheus"
sidebar_position: 40
---

Currently Kubecost is using a self hosted Prometheus instance within our Kubernetes cluster. You can update the Kubecost deployment configuration to use Amazon Managed Service for Prometheus (AMP) instead.

Amazon Managed Service for Prometheus is a Prometheus-compatible monitoring and alerting service that makes it easy to monitor containerized applications and infrastructure at scale. You can use the open-source Prometheus query language to monitor and alert for the performance of containerized workloads without having to worry about scaling the underlying monitoring infrastructure. The service automatically scales the ingestion, storage, alerting, and querying of operational metrics as workloads grow or shrink. Furthermore, it’s integrated with AWS security services to enable fast and secure access to data. This lets you concentrate on your workloads instead of having to manage your monitoring stack.

There are resources available online that can guide you through this process.

- [Amazon EKS cost monitoring with Kubecost and Amazon Managed Service for Prometheus (AMP)](https://blog.kubecost.com/blog/aws-amp-kubecost-integration/)
- [Amazon Web Services Blog](https://aws.amazon.com/blogs/mt/integrating-kubecost-with-amazon-managed-service-for-prometheus/)
- [Amazon Managed Service for Prometheus Documentation](https://docs.aws.amazon.com/prometheus/latest/userguide/integrating-kubecost.html#kubecost-set-up-amp)

The basics come down to:

1.  Setting up an AMP Workspace
2.  Creating IAM Roles for Services Accounts (IRSA) for the Kubecost resources

- `kubecost-prometheus-server`
- `kubecost-cost-analyzer`

  Both these service accounts will need Query and Write access to AMP. These can be given with the following policies:

  - `arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess`
  - `arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess`

3.  Update the Kubecost Helm `config-values.yaml` to reference the created AMP Workspace.

Below you can find an image explaining the architecture of the AMP Kubecost integration.
