---
title: "Ingress"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Ingress API를 사용하여 HTTP 및 HTTPS 경로를 외부 세계에 노출합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment exposing/ingress
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- AWS Load Balancer Controller에 필요한 IAM 역할 생성

[여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/ingress/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.
:::

Kubernetes Ingress is an API resource that allows you to manage external or internal HTTP(S) access to Kubernetes services running in a cluster. Amazon Elastic Load Balancing Application Load Balancer (ALB) is a popular AWS service that load balances incoming traffic at the application layer (layer 7) across multiple targets, such as Amazon EC2 instances, in a region. ALB supports multiple features including host or path based routing, TLS (Transport Layer Security) termination, WebSockets, HTTP/2, AWS WAF (Web Application Firewall) integration, integrated access logs, and health checks.

In this lab exercise, we'll expose our sample application using an ALB with the Kubernetes ingress model.