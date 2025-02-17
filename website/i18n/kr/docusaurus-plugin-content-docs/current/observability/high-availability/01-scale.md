---
title: "실습 설정: Chaos Mesh, 스케일링, 그리고 Pod 어피니티"
sidebar_position: 90
description: "Pod를 스케일링하고, Pod 안티-어피니티 설정을 추가하고, Pod 분산을 시각화하는 헬퍼 스크립트를 사용하는 방법을 배웁니다."
---

이 가이드는 고가용성 방식을 구현하여 UI 서비스의 복원력을 향상시키는 단계를 설명합니다. helm 설치, UI 서비스 스케일링, pod 안티-어피니티 구현, 그리고 가용성 영역 전반에 걸친 pod 분산을 시각화하는 헬퍼 스크립트 사용을 다룰 것입니다.

## Chaos Mesh 설치하기

클러스터의 복원력 테스트 기능을 향상시키기 위해 Chaos Mesh를 설치할 것입니다. Chaos Mesh는 Kubernetes 환경을 위한 강력한 카오스 엔지니어링 도구입니다. 이를 통해 다양한 장애 시나리오를 시뮬레이션하고 애플리케이션의 반응을 테스트할 수 있습니다.

Helm을 사용하여 클러스터에 Chaos Mesh를 설치해 보겠습니다:

```bash timeout=240
$ helm repo add chaos-mesh https://charts.chaos-mesh.org
$ helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --version 2.5.1 \
  --set dashboard.create=true \
  --wait

Release "chaos-mesh" does not exist. Installing it now.
NAME: chaos-mesh
LAST DEPLOYED: Tue Aug 20 04:44:31 2024
NAMESPACE: chaos-mesh
STATUS: deployed
REVISION: 1
TEST SUITE: None

```

## 스케일링과 토폴로지 분산 제약 조건

Kustomize 패치를 사용하여 UI 배포를 수정하고, 5개의 레플리카로 스케일링하며 토폴로지 분산 제약 조건 규칙을 추가합니다. 이를 통해 UI pod가 서로 다른 노드에 분산되어 노드 장애의 영향을 줄일 수 있습니다.

다음은 패치 파일의 내용입니다:

```kustomization
modules/observability/resiliency/high-availability/config/scale_and_affinity_patch.yaml
Deployment/ui
```

Kustomize 패치와 [Kustomization 파일](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/high-availability/config/kustomization.yaml)을 사용하여 변경사항을 적용합니다:

```bash timeout=120
$ kubectl delete deployment ui -n ui
$ kubectl apply -k ~/environment/eks-workshop/modules/observability/resiliency/high-availability/config/
```

## 리테일 스토어 접근성 확인

이러한 변경사항을 적용한 후, 리테일 스토어가 접근 가능한지 확인하는 것이 중요합니다:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

이 명령이 완료되면 URL이 출력됩니다. 새 브라우저 탭에서 이 URL을 열어 리테일 스토어가 접근 가능하고 올바르게 작동하는지 확인하세요.

:::tip
리테일 URL이 작동하기까지 5-10분이 소요될 수 있습니다.
:::

## 헬퍼 스크립트: 가용성 영역별 Pod 조회

`get-pods-by-az.sh` 스크립트는 터미널에서 서로 다른 가용성 영역에 걸친 Kubernetes pod의 분산을 시각화하는 데 도움을 줍니다. [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/scripts/get-pods-by-az.sh)에서 스크립트 파일을 볼 수 있습니다.

### 스크립트 실행

가용성 영역에 걸친 pod의 분산을 보려면 다음을 실행하세요:

```bash
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-6fzrk   1/1   Running   0     56s
       ui-6dfb84cf67-dsp55   1/1   Running   0     56s

------us-west-2b------
  ip-10-42-153-179.us-west-2.compute.internal:
       ui-6dfb84cf67-2pxnp   1/1   Running   0     59s

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-n8x4f   1/1   Running   0     61s
       ui-6dfb84cf67-wljth   1/1   Running   0     61s

```

:::info
이러한 변경사항에 대한 자세한 정보는 다음 섹션을 확인하세요:

- [Chaos Mesh](https://chaos-mesh.org/)
- [Pod 어피니티와 안티-어피니티](/docs/fundamentals/managed-node-groups/basics/affinity/)

:::