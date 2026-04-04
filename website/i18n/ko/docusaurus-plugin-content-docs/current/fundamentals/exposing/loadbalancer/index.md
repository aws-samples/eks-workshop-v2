---
title: "로드 밸런서"
chapter: true
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service의 워크로드로 트래픽을 라우팅하기 위해 AWS 로드 밸런서를 관리합니다."
tmdTranslationSourceHash: '566ba28a30cf59e7225d14d2c00ed04d'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment exposing/load-balancer
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- AWS Load Balancer Controller에 필요한 IAM role을 생성합니다

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/load-balancer/.workshop/terraform)에서 확인할 수 있습니다.

:::

Kubernetes는 Service를 사용하여 클러스터 외부에 Pod를 노출합니다. AWS에서 Service를 사용하는 가장 인기 있는 방법 중 하나는 `LoadBalancer` 타입을 사용하는 것입니다. Service 이름, 포트, 레이블 셀렉터를 선언하는 간단한 YAML 파일만으로 클라우드 컨트롤러가 자동으로 로드 밸런서를 프로비저닝합니다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: search-svc # Service 이름
spec:
# HIGHLIGHT
  type: LoadBalancer
  selector:
    app: SearchApp # app=SearchApp 레이블로 배포된 Pod
  ports:
    - port: 80
```

이는 애플리케이션 앞에 로드 밸런서를 배치하는 것이 얼마나 간단한지 보여주기 때문에 훌륭합니다. Service 스펙은 수년에 걸쳐 annotation과 추가 구성으로 확장되었습니다. 두 번째 옵션은 Ingress rule과 Ingress controller를 사용하여 외부 트래픽을 Kubernetes Pod로 라우팅하는 것입니다.

![IP mode](/docs/fundamentals/exposing/loadbalancer/ui-nlb-instance.webp)

이 장에서는 EKS 클러스터에서 실행 중인 애플리케이션을 레이어 4 Network Load Balancer를 사용하여 인터넷에 노출하는 방법을 시연합니다.

