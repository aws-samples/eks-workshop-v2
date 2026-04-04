---
title: "마무리"
sidebar_position: 33
tmdTranslationSourceHash: 'e9317f9dbd19894328c7118f601cd34c'
---

## AWS Load Balancer Controller 이해하기

AWS Load Balancer Controller가 Application Load Balancer(ALB)와 어떻게 작동하는지 학습한 내용을 복습해 보겠습니다. 이 아키텍처를 이해하면 향후 문제 해결에 도움이 됩니다.

### 핵심 구성 요소 및 흐름

1. **Controller 작동**
   * Controller는 Kubernetes API 서버에서 Ingress 이벤트를 지속적으로 감시합니다
   * 적격한 Ingress 리소스를 감지하면 해당 AWS 리소스 생성을 시작합니다
   * Controller는 이러한 AWS 리소스의 전체 수명 주기를 관리합니다

2. **Application Load Balancer (ALB)**
   * 각 Ingress 리소스에 대해 ALB가 생성됩니다
   * 인터넷 연결 또는 내부로 구성할 수 있습니다
   * 서브넷 배치는 어노테이션을 통해 제어됩니다
   * 생성 및 관리를 위한 적절한 IAM 권한이 필요합니다

3. **Target Group**
   * Ingress에 정의된 각 고유 Kubernetes Service에 대해 생성됩니다
   * 직접 Pod 등록을 위한 IP 모드 타겟팅을 지원합니다
   * 헬스 체크는 어노테이션을 통해 구성할 수 있습니다
   * 여러 Target Group을 다른 서비스에 사용할 수 있습니다

4. **Listener**
   * Ingress 어노테이션에 지정된 각 포트에 대해 생성됩니다
   * 지정되지 않은 경우 표준 포트(80/443)로 기본 설정됩니다
   * SSL/TLS 인증서 연결을 지원합니다
   * HTTP/HTTPS 트래픽에 대해 구성할 수 있습니다

5. **Rule**
   * Ingress 리소스의 경로 사양을 기반으로 생성됩니다
   * 적절한 Target Group으로 트래픽을 전달합니다
   * 경로 기반 및 호스트 기반 라우팅을 지원합니다
   * 복잡한 라우팅 시나리오를 위해 우선순위를 지정할 수 있습니다

### 일반적인 문제 해결 영역

이 모듈을 통해 몇 가지 일반적인 문제를 만나고 수정했습니다:

1. **서브넷 구성**
   * 퍼블릭 서브넷에는 `kubernetes.io/role/elb=1` 태그가 필요합니다
   * 프라이빗 서브넷에는 `kubernetes.io/role/internal-elb=1` 태그가 필요합니다
   * 서브넷은 라우팅 테이블과 적절하게 연결되어야 합니다

2. **IAM 권한**
   * Service Account에 적절한 IAM 역할이 필요합니다
   * 역할은 ALB 작업에 필요한 권한을 가져야 합니다
   * 일반적인 권한에는 로드 밸런서 및 Target Group 생성/수정이 포함됩니다

3. **Service 구성**
   * Service 셀렉터는 Pod 레이블과 정확히 일치해야 합니다
   * Service 포트는 컨테이너 포트와 일치해야 합니다
   * Service 이름은 Ingress 백엔드 구성과 일치해야 합니다

### 모범 사례

AWS Load Balancer Controller 작업 시:

* 인터넷 연결 ALB를 생성하기 전에 항상 서브넷 태그를 확인하세요
* ALB 동작을 제어하기 위해 명시적인 어노테이션을 사용하세요
* 문제 해결을 위해 Controller 로그를 모니터링하세요
* Service 엔드포인트 등록을 확인하세요
* Service와 Pod에 의미 있는 레이블을 사용하세요
* 사용자 정의 구성을 문서화하세요

:::tip
[AWS Load Balancer Controller 문서](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/)는 고급 구성 및 문제 해결을 위한 훌륭한 리소스입니다.
:::

