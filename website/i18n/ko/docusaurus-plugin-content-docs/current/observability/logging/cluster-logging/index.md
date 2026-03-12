---
title: "Control plane 로그"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "감사 및 진단을 위해 Amazon Elastic Kubernetes Service control plane 로그를 캡처하고 분석합니다."
tmdTranslationSourceHash: '8fb3e741f3feb886f47f3087641060bf'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment observability/logging/cluster
```

:::

Amazon EKS control plane 로깅은 Amazon EKS control plane에서 직접 감사 및 진단 로그를 계정의 CloudWatch Logs로 제공합니다. 이러한 로그를 통해 클러스터를 쉽게 보호하고 실행할 수 있습니다. 필요한 정확한 로그 유형을 선택할 수 있으며, 로그는 CloudWatch에서 각 Amazon EKS 클러스터에 대한 그룹으로 로그 스트림으로 전송됩니다.

AWS Management Console, AWS CLI(버전 1.16.139 이상) 또는 Amazon EKS API를 사용하여 클러스터별로 각 로그 유형을 활성화하거나 비활성화할 수 있습니다.

Amazon EKS control plane 로깅을 사용하면 실행하는 각 클러스터에 대해 표준 Amazon EKS 요금과 클러스터에서 CloudWatch Logs로 전송된 모든 로그에 대한 표준 CloudWatch Logs 데이터 수집 및 저장 비용이 청구됩니다.

다음 클러스터 control plane 로그 유형을 사용할 수 있습니다. 각 로그 유형은 Kubernetes control plane의 구성 요소에 해당합니다. 이러한 구성 요소에 대해 자세히 알아보려면 [Kubernetes 문서](https://kubernetes.io/docs/concepts/overview/components/)의 Kubernetes Components를 참조하세요.

- **Kubernetes API server component 로그 (api)** – 클러스터의 API server는 Kubernetes API를 노출하는 control plane 구성 요소입니다.
- **Audit (audit)** – Kubernetes 감사 로그는 클러스터에 영향을 준 개별 사용자, 관리자 또는 시스템 구성 요소의 기록을 제공합니다.
- **Authenticator (authenticator)** – Authenticator 로그는 Amazon EKS에 고유합니다. 이러한 로그는 Amazon EKS가 IAM 자격 증명을 사용하여 Kubernetes [Role Based Access Control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (RBAC) 인증에 사용하는 control plane 구성 요소를 나타냅니다.
- **Controller manager (controllerManager)** – controller manager는 Kubernetes와 함께 제공되는 핵심 제어 루프를 관리합니다.
- **Scheduler (scheduler)** – scheduler 구성 요소는 클러스터에서 Pod를 실행할 시기와 위치를 관리합니다.

