---
title: Using eksctl
sidebar_position: 20
---

이 섹션에서는 [`eksctl`](https://eksctl.io/) 도구를 사용하여 실습용 클러스터를 구축하는 방법을 설명합니다. 이는 시작하기 가장 쉬운 방법이며, 대부분의 학습자에게 권장됩니다.

`eksctl` 유틸리티는 `Amazon Cloud9` 환경에 사전 설치되어 있으므로 바로 클러스터를 생성할 수 있습니다. 다음은 클러스터를 구축하는 데 사용될 구성입니다:

```file hidePath=true
manifests/../cluster/eksctl/cluster.yaml
```

이 구성을 기반으로 `eksctl`은 다음을 수행합니다:

- 3개의 가용 영역에 걸쳐 VPC 생성
- EKS 클러스터 생성
- IAM OIDC 공급자 생성
- `default`라는 이름의 관리형 노드 그룹 추가
- `prefix delegation`을 사용하도록 `VPC CNI` 구성

다음과 같이 구성 파일을 적용하세요:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

이 과정은 20분 정도 소요됩니다.

## Next Steps

이제 클러스터가 준비되었으니, [실습 탐색](/docs/introduction/navigating-labs) 섹션으로 이동하거나 상단 네비게이션 바를 통해 워크샵의 어떤 모듈로든 건너뛸 수 있습니다. 워크샵을 완료한 후에는 아래 단계에 따라 환경을 정리하세요.

## 정리하기 (워크샵을 마친 후의 단계들)

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