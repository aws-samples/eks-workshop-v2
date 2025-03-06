---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 Ingress API를 사용하여 HTTP 및 HTTPS 경로를 외부 세계에 노출합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment exposing/ingress
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- AWS Load Balancer 컨트롤러에 필요한 IAM 역할 생성

[여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/ingress/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.
:::

쿠버네티스 Ingress는 클러스터에서 실행되는 쿠버네티스 서비스에 대한 외부 또는 내부 HTTP(S) 접근을 관리할 수 있게 해주는 API 리소스입니다. Amazon Application Load Balancer(ALB)는 한 리전의 Amazon EC2 인스턴스와 같은 여러 대상에 걸쳐 애플리케이션 계층(Layer 7)에서 들어오는 트래픽을 로드 밸런싱하는 인기 있는 AWS 서비스입니다. ALB는 호스트 또는 경로 기반 라우팅, TLS(Transport Layer Security) 종료, WebSockets, HTTP/2, AWS WAF(Web Application Firewall) 통합, 통합 접근 로그, 상태 확인을 포함한 여러 기능을 지원합니다.

이 실습에서는 쿠버네티스 ingress 모델을 사용하여 ALB로 샘플 애플리케이션을 노출할 것입니다.