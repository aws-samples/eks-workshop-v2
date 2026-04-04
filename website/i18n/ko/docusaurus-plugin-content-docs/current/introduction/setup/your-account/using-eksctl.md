---
title: eksctl 사용하기
sidebar_position: 20
tmdTranslationSourceHash: '64bca6c359b7e98745bbfb3b91d91197'
---

이 섹션에서는 [eksctl 도구](https://eksctl.io/)를 사용하여 실습 환경용 클러스터를 구축하는 방법을 설명합니다. 이것은 가장 쉽게 시작할 수 있는 방법이며, 대부분의 학습자에게 권장됩니다.

`eksctl` 유틸리티는 여러분의 웹 IDE 환경에 사전 설치되어 있으므로, 즉시 클러스터를 생성할 수 있습니다. 다음은 클러스터를 구축하는 데 사용될 구성입니다:

::yaml{file="manifests/../cluster/eksctl/cluster.yaml" paths="availabilityZones,metadata.name,iam,managedNodeGroups,addons.0.configurationValues" title="cluster.yaml"}

1. 3개의 가용 영역에 걸쳐 VPC 생성
2. 기본적으로 `eks-workshop`이라는 이름의 EKS 클러스터 생성
3. IAM OIDC 공급자 생성
4. `default`라는 이름의 관리형 노드 그룹 추가
5. Prefix Delegation을 사용하도록 VPC CNI 구성

다음과 같이 구성 파일을 적용합니다:

```bash
$ export EKS_CLUSTER_NAME=eks-workshop
$ curl -fsSL https://raw.githubusercontent.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/VAR::MANIFESTS_REF/cluster/eksctl/cluster.yaml | \
envsubst | eksctl create cluster -f -
```

이 프로세스는 완료되는 데 약 20분이 소요됩니다.

## 다음 단계

이제 클러스터가 준비되었으므로 [실습 탐색하기](/docs/introduction/navigating-labs) 섹션으로 이동하거나 상단 탐색 메뉴를 사용하여 워크샵의 모든 모듈로 바로 건너뛸 수 있습니다. 워크샵을 완료한 후에는 아래 단계에 따라 환경을 정리하세요.

## 정리하기 (워크샵 완료 후 단계)

:::tip
다음은 EKS 클러스터 사용을 완료한 후 리소스를 정리하는 방법을 보여줍니다. 이 단계를 완료하면 AWS 계정에 대한 추가 요금이 발생하지 않습니다.
:::

IDE 환경을 삭제하기 전에 이전 단계에서 설정한 클러스터를 정리합니다.

먼저, `delete-environment`를 사용하여 샘플 애플리케이션과 남아있는 실습 인프라가 제거되도록 합니다:

```bash
$ delete-environment
```

다음으로, `eksctl`을 사용하여 클러스터를 삭제합니다:

```bash
$ eksctl delete cluster $EKS_CLUSTER_NAME --wait
```

이제 IDE [정리하기](./cleanup.md)를 진행할 수 있습니다.

