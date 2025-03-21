---
title: "Pod 로깅"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 실행되는 pod의 워크로드 로그를 캡처합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment observability/logging/pods
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon EKS 클러스터에 AWS for Fluent Bit 설치

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/logging/pods/.workshop/terraform)에서 확인할 수 있습니다.
:::

현대적인 애플리케이션 아키텍처의 골드 스탠다드를 제공하는 [Twelve-Factor App 선언](https://12factor.net/)에 따르면, 컨테이너화된 애플리케이션은 [로그를 stdout과 stderr로 출력](https://12factor.net/logs)해야 합니다. 이는 Kubernetes에서도 모범 사례로 간주되며 클러스터 수준의 로그 수집 시스템은 이러한 전제를 기반으로 구축됩니다.

Kubernetes 로깅 아키텍처는 세 가지 distinct 수준을 정의합니다:

- 기본 수준 로깅: kubectl을 사용하여 pod 로그를 가져오는 기능(예: `kubectl logs myapp` - 여기서 `myapp`은 클러스터에서 실행 중인 pod)
- 노드 수준 로깅: 컨테이너 엔진이 애플리케이션의 `stdout`과 `stderr`에서 로그를 캡처하여 로그 파일에 기록합니다.
- 클러스터 수준 로깅: 노드 수준 로깅을 기반으로 하며, 로그 캡처 에이전트가 각 노드에서 실행됩니다. 에이전트는 로컬 파일시스템에서 로그를 수집하여 Elasticsearch나 CloudWatch와 같은 중앙 집중식 로깅 대상으로 전송합니다. 에이전트는 두 가지 유형의 로그를 수집합니다:
  - 노드의 컨테이너 엔진이 캡처한 컨테이너 로그
  - 시스템 로그

Kubernetes는 자체적으로 로그를 수집하고 저장하는 네이티브 솔루션을 제공하지 않습니다. 대신 컨테이너 런타임이 로컬 파일시스템에 JSON 형식으로 로그를 저장하도록 구성합니다. Docker와 같은 컨테이너 런타임은 컨테이너의 stdout과 stderr 스트림을 로깅 드라이버로 리디렉션합니다. Kubernetes에서 컨테이너 로그는 노드의 `/var/log/pods/*.log`에 기록됩니다. Kubelet과 컨테이너 런타임은 자체 로그를 `/var/logs` 또는 systemd가 있는 운영체제의 경우 journald에 기록합니다. 그런 다음 Fluentd와 같은 클러스터 전체 로그 수집기 시스템이 노드의 이러한 로그 파일을 추적하여 보관을 위해 로그를 전송할 수 있습니다. 이러한 로그 수집기 시스템은 일반적으로 워커 노드에서 DaemonSet으로 실행됩니다.

이 실습에서는 EKS의 노드에서 로그를 수집하여 CloudWatch Logs로 전송하도록 로그 에이전트를 설정하는 방법을 보여드리겠습니다.

:::info
CDK Observability Accelerator를 사용하는 경우 [AWS for Fluent Bit Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-for-fluent-bit/)을 확인하세요. AWS for FluentBit 애드온은 CloudWatch, Amazon Kinesis, AWS OpenSearch를 포함한 여러 AWS 대상으로 로그를 전달하도록 구성할 수 있습니다.
:::