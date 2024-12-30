---
title: Using eksctl
sidebar_position: 20
---

이 섹션에서는 [`eksctl`](https://eksctl.io/) 도구를 사용하여 실습용 클러스터를 구축하는 방법을 설명합니다. 이는 시작하기 가장 쉬운 방법이며, 대부분의 학습자에게 권장됩니다.

`eksctl` 유틸리티는 `Amazon Cloud9` 환경에 사전 설치되어 있으므로 바로 클러스터를 생성할 수 있습니다. 다음은 클러스터를 구축하는 데 사용될 구성입니다:

```file hidePath=true
manifests/../cluster/eksctl/cluster.yaml
```

Based on this configuration `eksctl` will:

- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Apply the configuration file like so:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

This process will take around 20 minutes.

## Next Steps

Now that the cluster is ready, head to the [Navigating the labs](/docs/introduction/navigating-labs) section or skip ahead to any module in the workshop with the top navigation bar. Once you're completed with the workshop, follow the steps below to clean-up your environment.

## Cleaning Up (steps once you are done with the Workshop)

:::tip
The following demonstrates how you will later clean up resources once you are done using the EKS cluster you created in previous steps to complete the modules.\
:::

Before deleting the Cloud9/VSCode IDE environment we need to clean up the cluster that we set up in previous steps.

First use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next delete the cluster with `eksctl`:

```bash
$ eksctl delete cluster $EKS_CLUSTER_NAME --wait
```