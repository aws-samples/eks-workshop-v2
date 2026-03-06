---
title: Terraform 사용하기
sidebar_position: 30
tmdTranslationSourceHash: '0e3724e9afa0ee9b592cd183d26f5329'
---

:::warning
Terraform을 사용한 워크샵 클러스터 생성은 현재 프리뷰 상태입니다. 발생한 문제는 [GitHub 리포지토리](https://github.com/aws-samples/eks-workshop-v2/issues)에 제기해 주세요.
:::

이 섹션에서는 [HashiCorp Terraform](https://developer.hashicorp.com/terraform)을 사용하여 실습용 클러스터를 구축하는 방법을 설명합니다. 이는 Terraform infrastructure-as-code 사용에 익숙한 학습자를 위한 것입니다.

`terraform` CLI는 웹 IDE 환경에 사전 설치되어 있으므로 즉시 클러스터를 생성할 수 있습니다. 클러스터와 지원 인프라를 구축하는 데 사용될 주요 Terraform 구성 파일을 살펴보겠습니다.

## Terraform 구성 파일 이해하기

`providers.tf` 파일은 인프라를 구축하는 데 필요한 Terraform provider를 구성합니다. 여기서는 `aws`, `kubernetes`, `helm` provider를 사용합니다:

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

`main.tf` 파일은 현재 사용 중인 AWS 계정과 리전을 가져오기 위한 Terraform 데이터 소스와 일부 기본 태그를 설정합니다:

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

`vpc.tf` 구성은 VPC 인프라가 생성되도록 합니다:

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

마지막으로 `eks.tf` 파일은 Managed Node Group을 포함한 EKS 클러스터 구성을 지정합니다:

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Terraform으로 워크샵 환경 생성하기

이 구성을 기반으로 Terraform은 다음과 같이 워크샵 환경을 생성합니다:

- 세 개의 가용 영역에 걸친 VPC
- EKS 클러스터
- IAM OIDC provider
- `default`라는 이름의 managed node group
- Prefix Delegation을 사용하도록 구성된 VPC CNI

Terraform 파일을 다운로드합니다:

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

다음 Terraform 명령을 실행하여 워크샵 환경을 배포합니다:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

이 프로세스는 일반적으로 완료되는 데 20-25분이 걸립니다.

## 다음 단계

이제 클러스터가 준비되었으므로 [실습 둘러보기](/docs/introduction/navigating-labs) 섹션으로 이동하거나 상단 내비게이션 바를 사용하여 워크샵의 모든 모듈로 건너뛸 수 있습니다. 워크샵을 완료한 후에는 아래 단계에 따라 환경을 정리하세요.

## 정리하기 (워크샵 완료 후 단계)

:::warning
다음은 EKS 클러스터 사용을 완료한 후 리소스를 정리하는 방법을 보여줍니다. 이 단계를 완료하면 AWS 계정에 대한 추가 요금이 발생하지 않습니다.
:::

IDE 환경을 삭제하기 전에 이전 단계에서 설정한 클러스터를 정리합니다.

먼저 `delete-environment`를 사용하여 샘플 애플리케이션과 남아있는 실습 인프라가 제거되었는지 확인합니다:

```bash
$ delete-environment
```

다음으로 `terraform`을 사용하여 클러스터를 삭제합니다:

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

이제 IDE [정리하기](./cleanup.md)를 진행할 수 있습니다.

