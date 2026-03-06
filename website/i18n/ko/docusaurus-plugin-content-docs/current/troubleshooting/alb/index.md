---
title: "ALB Controller"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: 'b36bbab8cf13755387c757ff2b77d0d3'
---

::required-time

이 실습에서는 Amazon EKS 작업 시 발생할 수 있는 일반적인 문제들을 살펴보고 효과적인 트러블슈팅 기술을 배웁니다. AWS Load Balancer Controller 및 서비스 연결 문제에 중점을 두고 실제 시나리오를 다룰 것입니다. Load Balancer Controller의 작동 방식에 대해 더 자세히 알고 싶다면 [Fundamentals 모듈](/docs/fundamentals/) 또는 [AWS LB Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) 공식 문서를 참조하세요.

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=10
$ prepare-environment troubleshooting/alb
```
이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/alb/.workshop/terraform)에서 확인할 수 있습니다.
:::
:::info

실습 준비에는 몇 분이 소요될 수 있으며 실습 환경에 다음과 같은 변경 사항을 적용합니다:


- 샘플 UI 애플리케이션 배포
- Ingress 리소스 구성
- 초기 AWS Load Balancer Controller 구성 설정 (트러블슈팅을 위한 의도적인 문제 포함)
- 필요한 IAM 역할 및 정책 생성

:::

## 환경 설정 세부 사항

prepare-environment 스크립트는 트러블슈팅을 위한 특정 문제들과 함께 여러 리소스를 생성했습니다:

- ui 네임스페이스의 UI 애플리케이션 배포
- AWS Load Balancer Controller를 사용하도록 구성된 Ingress 리소스
- IAM 역할 및 정책 (의도적인 잘못된 구성 포함)
- Kubernetes 서비스 리소스

이러한 컴포넌트들은 이 모듈 전반에 걸쳐 식별하고 수정할 일반적인 실제 문제들로 구성되어 있습니다.

## 다룰 내용

다음과 같은 여러 문제를 트러블슈팅합니다:

- ALB 생성을 방해하는 누락되거나 잘못된 서브넷 태그
- Load Balancer Controller를 차단하는 IAM 권한 문제
- 서비스 셀렉터 잘못된 구성
- Ingress 백엔드 서비스 문제

## 사전 요구 사항

진행하기 전에 다음을 확인하세요:

- EKS 클러스터에 대한 액세스
- 적절한 AWS CLI 구성
- kubectl이 설치되고 구성됨
- Kubernetes 네트워킹 개념에 대한 기본 이해

## 사용할 도구

이 모듈 전반에 걸쳐 다음 트러블슈팅 도구를 사용합니다:

- Kubernetes 리소스 검사를 위한 kubectl 명령
- AWS 리소스 상태 확인을 위한 AWS CLI
- Controller 진단을 위한 CloudWatch Logs
- 권한 검증을 위한 AWS IAM 도구

:::tip 계속하기 전에
prepare-environment 스크립트를 실행한 후 몇 분 후, 서비스와 Ingress가 정상적으로 실행 중인지 확인하세요.

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.224.112   <none>        80/TCP    12d
```

```bash
$ kubectl get ingress -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      11m

```

로드 밸런서가 실제로 생성되지 않았는지 확인해 봅시다:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[]
```

:::
Application Load Balancer가 생성되지 않는 이유를 조사해 봅시다!

