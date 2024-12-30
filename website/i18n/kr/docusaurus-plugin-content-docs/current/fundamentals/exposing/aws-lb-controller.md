---
title: "AWS Load Balancer Controller"
sidebar_position: 20
---

**AWS Load Balancer Controller**는 Kubernetes 클러스터의 Elastic Load Balancer를 관리하는 데 도움을 주는 [**컨트롤러**](https://kubernetes.io/docs/concepts/architecture/controller/)입니다.

컨트롤러는 다음과 같은 리소스를 프로비저닝할 수 있습니다:

- Kubernetes `Ingress`를 생성할 때 AWS Application Load Balancer
- `LoadBalancer` 유형의 Kubernetes `Service`를 생성할 때 AWS Network Load Balancer

**Application Load Balancer**는 OSI 모델의 `L7`에서 작동하여 ingress 규칙을 사용하여 Kubernetes 서비스를 노출할 수 있게 하며, 외부 트래픽을 지원합니다. **Network Load Balancer**는 OSI 모델의 `L4`에서 작동하여 Kubernetes Service를 사용해 pod 집합을 애플리케이션 네트워크 서비스로 노출할 수 있게 합니다.

컨트롤러를 사용하면 Kubernetes 클러스터의 여러 애플리케이션에서 Application Load Balancer를 공유하여 운영을 단순화하고 비용을 절감할 수 있습니다.

다음 섹션에서는 AWS Load Balancer Controller 설치 단계를 소개하여 AWS에서 Load Balancer 리소스 생성을 시작할 수 있도록 할 것입니다.

:::info
AWS Load Balancer Controller는 이전에 AWS ALB Ingress Controller로 불렸습니다.
:::