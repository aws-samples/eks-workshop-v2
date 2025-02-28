---
title: "컨트롤 플레인 로그"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "감사 및 진단을 위해 Amazon Elastic Kubernetes Service(EKS) 컨트롤 플레인 로그를 캡처하고 분석합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment observability/logging/cluster
```

:::

Amazon EKS 컨트롤 플레인 로깅은 Amazon EKS 컨트롤 플레인에서 직접 CloudWatch Logs로 감사 및 진단 로그를 제공합니다. 이러한 로그를 통해 클러스터를 쉽게 보호하고 운영할 수 있습니다. 필요한 정확한 로그 유형을 선택할 수 있으며, 로그는 CloudWatch의 각 Amazon EKS 클러스터에 대한 그룹으로 로그 스트림으로 전송됩니다.

AWS Management Console, AWS CLI(버전 1.16.139 이상) 또는 Amazon EKS API를 통해 클러스터별로 각 로그 유형을 활성화하거나 비활성화할 수 있습니다.

Amazon EKS 컨트롤 플레인 로깅을 사용할 때는 실행하는 각 클러스터에 대한 표준 Amazon EKS 요금과 함께 클러스터에서 CloudWatch Logs로 전송되는 모든 로그에 대한 표준 CloudWatch Logs 데이터 수집 및 저장 비용이 청구됩니다.

다음과 같은 클러스터 컨트롤 플레인 로그 유형을 사용할 수 있습니다. 각 로그 유형은 Kubernetes 컨트롤 플레인의 구성 요소에 해당합니다. 이러한 구성 요소에 대해 자세히 알아보려면 [Kubernetes 문서](https://kubernetes.io/docs/concepts/overview/components/)의 Kubernetes 구성 요소를 참조하세요.

- **Kubernetes API 서버 구성 요소 로그(api)** - 클러스터의 API 서버는 Kubernetes API를 노출하는 컨트롤 플레인 구성 요소입니다.
- **감사(audit)** - Kubernetes 감사 로그는 클러스터에 영향을 미친 개별 사용자, 관리자 또는 시스템 구성 요소의 기록을 제공합니다.
- **인증자(authenticator)** - 인증자 로그는 Amazon EKS에만 고유합니다. 이러한 로그는 Amazon EKS가 IAM 자격 증명을 사용하여 Kubernetes [역할 기반 접근 제어](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)(RBAC) 인증에 사용하는 컨트롤 플레인 구성 요소를 나타냅니다.
- **컨트롤러 관리자(controllerManager)** - 컨트롤러 관리자는 Kubernetes와 함께 제공되는 핵심 제어 루프를 관리합니다.
- **스케줄러(scheduler)** - 스케줄러 구성 요소는 클러스터에서 파드를 실행할 시기와 위치를 관리합니다.