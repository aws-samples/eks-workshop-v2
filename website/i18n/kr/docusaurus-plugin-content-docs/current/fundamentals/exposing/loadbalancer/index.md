---
title: "Load Balancers"
chapter: true
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Manage AWS load balancers to route traffic to workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment exposing/load-balancer
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Creates an IAM role required by the AWS Load Balancer Controller

[**여기**](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/load-balancer/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.
:::

Kubernetes는 서비스를 사용하여 클러스터 외부에 pod를 노출합니다. AWS에서 서비스를 사용하는 가장 인기 있는 방법 중 하나는 `LoadBalancer` 유형을 사용하는 것입니다. 서비스 이름, 포트, 레이블 선택기(Selector)를 선언하는 간단한 YAML 파일로 클라우드 컨트롤러가 자동으로 로드 밸런서를 프로비저닝합니다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: search-svc # the name of our service
spec:
  type: loadBalancer
  selector:
    app: SearchApp # pods are deployed with the label app=SearchApp
  ports:
    - port: 80
```

This is great because of how simple it is to put a load balancer in front of your application. The service spec has been extended over the years with annotations and additional configuration. A second option is to use an ingress rule and an ingress controller to route external traffic into Kubernetes pods.

![IP mode](./assets/ui-nlb-instance.webp)

In this chapter we'll demonstrate how to expose an application running in the EKS cluster to the Internet using a layer 4 Network Load Balancer.