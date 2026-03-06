---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Ingress API를 사용하여 HTTP 및 HTTPS 경로를 외부에 노출합니다."
tmdTranslationSourceHash: "72d939af908c33198aba9c59be5e701d"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment exposing/ingress
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- AWS Load Balancer Controller에 필요한 IAM 역할 생성
- ExternalDNS에 필요한 IAM 역할 생성
- AWS Route 53 프라이빗 호스팅 영역 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/ingress/.workshop/terraform)에서 확인할 수 있습니다.

:::

Kubernetes Ingress는 클러스터에서 실행 중인 Kubernetes 서비스에 대한 외부 또는 내부 HTTP(S) 액세스를 관리할 수 있는 API 리소스입니다. Amazon Elastic Load Balancing Application Load Balancer(ALB)는 리전 내 여러 대상(예: Amazon EC2 인스턴스)에서 애플리케이션 계층(계층 7)의 수신 트래픽을 로드 밸런싱하는 인기 있는 AWS 서비스입니다. ALB는 호스트 또는 경로 기반 라우팅, TLS(전송 계층 보안) 종료, WebSocket, HTTP/2, AWS WAF(Web Application Firewall) 통합, 통합 액세스 로그 및 상태 확인을 포함한 여러 기능을 지원합니다.

이 실습에서는 Kubernetes Ingress 모델을 사용하여 ALB로 샘플 애플리케이션을 노출합니다.

