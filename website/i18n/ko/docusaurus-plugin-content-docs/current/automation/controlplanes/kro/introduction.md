---
title: "소개"
sidebar_position: 3
tmdTranslationSourceHash: '38be1b73207e74a7b4e3a0e965e3fc63'
---

kro는 두 가지 주요 구성 요소를 사용하여 클러스터 내에서 작동합니다:

1. 핵심 오케스트레이션 기능을 제공하는 kro controller manager
2. 관련 리소스 그룹을 생성하기 위한 템플릿을 정의하는 ResourceGraphDefinitions (RGD)

kro controller manager는 ResourceGraphDefinition 커스텀 리소스를 감시하고 템플릿에 정의된 기본 Kubernetes 리소스의 생성 및 관리를 오케스트레이션합니다.

kro는 플랫폼 팀이 여러 관련 리소스를 캡슐화하는 ResourceGraphDefinitions를 정의할 수 있도록 하여 복잡한 리소스 관리를 간소화합니다. 개발자는 RGD 스키마에 의해 정의된 간단한 커스텀 API와 상호 작용하고, kro는 기본 리소스의 생성 및 관리의 복잡성을 처리합니다. 이 아키텍처는 ResourceGraphDefinitions를 정의하는 플랫폼 팀과 간소화된 커스텀 API를 사용하여 복잡한 리소스 그룹을 생성하는 애플리케이션 개발자 간의 명확한 분리를 제공합니다.

먼저 Helm 차트를 사용하여 Kubernetes 클러스터에 kro를 설치해 보겠습니다:

```bash wait=60
$ helm install oci://registry.k8s.io/kro/charts/kro \
  --version=${KRO_VERSION} \
  --namespace kro-system --create-namespace \
  --wait
```

kro controller가 실행 중인지 확인합니다:

```bash
$ kubectl get deployment -n kro-system
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
kro     1/1     1            1           13s
```

또한 kro 커스텀 리소스 정의가 설치되었는지 확인할 수 있습니다:

```bash
$ kubectl get crd | grep kro
resourcegraphdefinitions.kro.run          2025-10-15T22:34:13Z
```

ResourceGraphDefinition을 생성하면 kro는 다음을 수행합니다:

1. **새로운 커스텀 API 등록** - RGD에 정의된 스키마를 기반으로 kro는 개발자가 사용할 수 있는 새로운 Kubernetes CRD를 자동으로 생성합니다
2. **리소스 인스턴스 처리** - 개발자가 커스텀 API의 인스턴스를 생성하면 kro는 정의된 템플릿을 사용하여 요청을 처리합니다
3. **CEL 표현식 평가** - kro는 Common Expression Language (CEL)를 사용하여 조건을 평가하고, 리소스 간에 값을 전달하며, 생성 순서를 결정합니다
4. **지능적으로 종속성 처리** - kro는 리소스가 서로를 참조하는 방식을 자동으로 분석하고 수동 구성 없이 최적의 배포 순서를 결정합니다
5. **관리되는 리소스 생성** - 템플릿과 종속성 분석을 기반으로 kro는 올바른 순서로 지정된 Kubernetes 리소스를 생성합니다
6. **관계 유지** - kro는 리소스 간의 종속성을 추적하고 적절한 라이프사이클 관리를 보장합니다

