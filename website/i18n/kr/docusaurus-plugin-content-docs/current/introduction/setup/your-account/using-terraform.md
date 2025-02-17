---
title: Terraform 사용하기
sidebar_position: 30
---

:::warning

Terraform을 사용한 워크샵 클러스터 생성은 현재 미리보기 상태입니다. [GitHub 저장소](https://github.com/aws-samples/eks-workshop-v2/issues)에서 발견된 문제점을 제보해 주세요.

:::

이 섹션에서는 [Hashicorp Terraform](https://developer.hashicorp.com/terraform)을 사용하여 실습용 클러스터를 구축하는 방법을 설명합니다. 이는 Terraform Iac(Infrastructure-As-Code) 작업에 익숙한 학습자를 위한 것입니다.

`terraform CLI`가 IDE에 사전 설치되어 있으므로 바로 클러스터를 생성할 수 있습니다. 클러스터와 지원 인프라를 구축하는 데 사용될 주요 Terraform 구성 파일을 살펴보겠습니다.

## Terraform 구성 파일 이해하기

`providers.tf` 파일은 인프라를 구축하는 데 필요한 Terraform 공급자를 구성합니다. 우리의 경우 `aws`, `kubernetes` 및 `helm` 공급자를 사용합니다:

```file hidePath=true
manifests/../cluster/terraform/providers.tf
```

`main.tf `파일은 현재 사용 중인 AWS 계정과 리전을 검색할 수 있도록 Terraform 데이터 소스를 설정하고, 일부 기본 태그도 설정합니다:

```file hidePath=true
manifests/../cluster/terraform/main.tf
```

`vpc.tf` 구성은 VPC 인프라가 생성되도록 보장합니다:

```file hidePath=true
manifests/../cluster/terraform/vpc.tf
```

마지막으로, `eks.tf` 파일은 관리형 노드 그룹을 포함한 EKS 클러스터 구성을 지정합니다:

```file hidePath=true
manifests/../cluster/terraform/eks.tf
```

## Terraform으로 워크샵 환경 만들기

주어진 구성에 대해 `terraform`은 다음과 같이 워크샵 환경을 생성합니다:

- 3개의 가용 영역에 걸쳐 VPC 생성
- EKS 클러스터 생성
- IAM OIDC 공급자 생성
- `default`라는 이름의 관리형 노드 그룹 추가
- `prefix delegation`을 사용하도록 VPC CNI 구성

Terraform 파일 다운로드

```bash
$ mkdir -p ~/environment/terraform; cd ~/environment/terraform
$ curl --remote-name-all https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

다음 Terraform 명령을 실행하여 워크샵 환경을 배포하세요.

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ terraform init
$ terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```

일반적으로 완료하는 데 20-25분이 소요됩니다.

## 다음 단계

이제 클러스터가 준비되었으니, [실습 탐색](/docs/introduction/navigating-labs) 섹션으로 이동하거나 상단 네비게이션 바를 통해 워크샵의 어떤 모듈로든 건너뛸 수 있습니다. 워크샵을 완료한 후에는 아래 단계에 따라 환경을 정리하세요.

## 정리하기

:::warning

다음은 원하는 실습 과정을 완료한 후 리소스를 정리하는 방법을 보여줍니다. 이 단계들은 프로비저닝된 모든 인프라를 삭제합니다.

:::

Cloud9/VSCode IDE 환경을 삭제하기 전에 위에서 설정한 클러스터를 정리해야 합니다.

먼저 `delete-environment`를 사용하여 샘플 애플리케이션과 남아있는 실습 인프라가 제거되었는지 확인하세요:

```bash
$ delete-environment
```

다음으로 `terraform`을 사용하여 클러스터를 삭제하세요:

```bash
$ cd ~/environment/terraform
$ terraform destroy -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```