---
title: "Storing metrics with AMP"
sidebar_position: 20
---

Amazon Managed Service for Prometheus is a monitoring service for metrics compatible with the open source Prometheus project, making it easier for you to securely monitor container environments. Amazon Managed Service for Prometheus is a solution for monitoring containers based on the popular Cloud Native Computing Foundation (CNCF) Prometheus project. Amazon Managed Service for Prometheus is powered by Cortex, an open source CNCF project that adds horizontal scalability to ingest, store, query, and alert on Prometheus metrics. Amazon Managed Service for Prometheus reduces the heavy lifting required to get started with monitoring applications across Amazon Elastic Kubernetes Service and Amazon Elastic Container Service, as well as self-managed Kubernetes clusters. Amazon Managed Service for Prometheus automatically scales as your monitoring needs grow. It offers highly available, multi-Availability Zone deployments, and integrates AWS security and compliance capabilities. Amazon Managed Service for Prometheus offers native support for the PromQL query language as well as over 150+ Prometheus exporters maintained by the open source community.

An Amazon Managed Service for Prometheus workspace is already created for you. You should be able to see it in the console:

https://console.aws.amazon.com/prometheus/home

To view the workspace, click on the <i>All Workspaces</i> tab on the left control panel. Select the workspace that starts with **eks-workshop** and you can view several the several tabs under the workspace such as rules management, alert manager etc.

Let's verify the successful ingestion of the metrics using `awscurl`:

```bash
$ awscurl -X POST --region $AWS_DEFAULT_REGION --service aps "${AMP_ENDPOINT}api/v1/query?query=up" | jq '.data.result[1]'
{
  "metric": {
    "__name__": "up",
    "account_id": "1234567890",
    "beta_kubernetes_io_arch": "amd64",
    "beta_kubernetes_io_instance_type": "m5.large",
    "beta_kubernetes_io_os": "linux",
    "cluster": "eks-workshop-cluster",
    "eks_amazonaws_com_capacityType": "ON_DEMAND",
    "eks_amazonaws_com_nodegroup": "managed-ondemand-2022110404042617720000001b",
    "eks_amazonaws_com_nodegroup_image": "ami-01dfb5782bffd09d6",
    "eks_amazonaws_com_sourceLaunchTemplateId": "lt-0566ef61fb851d6e1",
    "eks_amazonaws_com_sourceLaunchTemplateVersion": "1",
    "failure_domain_beta_kubernetes_io_region": "us-west-2",
    "failure_domain_beta_kubernetes_io_zone": "us-west-2c",
    "instance": "ip-10-42-12-99.us-west-2.compute.internal",
    "job": "kubernetes-kubelet",
    "k8s_io_cloud_provider_aws": "ffc60533e6d069826fca0578b02694a2",
    "kubernetes_io_arch": "amd64",
    "kubernetes_io_hostname": "ip-10-42-12-99.us-west-2.compute.internal",
    "kubernetes_io_os": "linux",
    "node_kubernetes_io_instance_type": "m5.large",
    "region": "us-west-2",
    "topology_ebs_csi_aws_com_zone": "us-west-2c",
    "topology_kubernetes_io_region": "us-west-2",
    "topology_kubernetes_io_zone": "us-west-2c",
    "workshop_default": "yes"
  },
  "value": [
    1667597359,
    "1"
  ]
}
```

