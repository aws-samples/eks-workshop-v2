---
title: Using Terraform
sidebar_position: 30
---

:::warning

Terraform을 사용한 워크샵 클러스터 생성은 현재 미리보기 상태입니다. [GitHub 저장소](https://github.com/aws-samples/eks-workshop-v2/issues)에서 발견된 문제점을 제보해 주세요.

:::

이 섹션에서는 [Hashicorp Terraform](https://developer.hashicorp.com/terraform)을 사용하여 실습용 클러스터를 구축하는 방법을 설명합니다. 이는 Terraform Iac(Infrastructure-As-Code) 작업에 익숙한 학습자를 위한 것입니다.

`terraform CLI`가 IDE에 사전 설치되어 있으므로 바로 클러스터를 생성할 수 있습니다. 클러스터와 지원 인프라를 구축하는 데 사용될 주요 Terraform 구성 파일을 살펴보겠습니다.

### Terraform 구성 파일 이해하기

`providers.tf` 파일은 인프라를 구축하는 데 필요한 Terraform 공급자를 구성합니다. 우리의 경우 `aws`, `kubernetes` 및 `helm` 공급자를 사용합니다:

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

`main.tf `파일은 현재 사용 중인 AWS 계정과 리전을 검색할 수 있도록 Terraform 데이터 소스를 설정하고, 일부 기본 태그도 설정합니다:

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

The `vpc.tf` configuration will make sure our VPC infrastructure is created:

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

Finally, the `eks.tf` file specifies our EKS cluster configuration, including a Managed Node Group:

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Creating the workshop environment with Terraform

For the given configuration, `terraform` will create the Workshop environment with the following:

- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named `default`
- Configure the VPC CNI to use prefix delegation

Download the Terraform files:

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

Run the following Terraform commands to deploy your workshop environment.

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

This generally takes 20-25 minutes to complete.

## Next Steps

Now that the cluster is ready, head to the [Navigating the labs](/docs/introduction/navigating-labs) section or skip ahead to any module in the workshop with the top navigation bar. Once you're completed with the workshop, follow the steps below to clean-up your environment.

## Cleaning Up

:::warning
The following demonstrates how you will later clean up resources once you have completed your desired lab exercises. These steps will delete all provisioned infrastructure.
:::

Before deleting the Cloud9/VSCode IDE environment we need to clean up the cluster that we set up above.

First use `delete-environment` to ensure that the sample application and any left-over lab infrastructure is removed:

```bash
$ delete-environment
```

Next delete the cluster with `terraform`:

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```