---
title: "EKS 콘솔 보기"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS) 콘솔에서 Kubernetes 리소스의 가시성을 확보합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment
```

:::

이 실습에서는 Amazon EKS용 AWS Management Console을 사용하여 모든 Kubernetes API 리소스 유형을 볼 것입니다. 구성, 인증 리소스, 정책 리소스, 서비스 리소스 등 모든 표준 Kubernetes API 리소스 유형을 보고 탐색할 수 있습니다. [Kubernetes 리소스 뷰](https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html)는 Amazon EKS에서 호스팅하는 모든 Kubernetes 클러스터에서 지원됩니다. [Amazon EKS Connector](https://docs.aws.amazon.com/eks/latest/userguide/eks-connector.html)를 사용하여 모든 규격 Kubernetes 클러스터를 AWS에 등록하고 연결하여 Amazon EKS 콘솔에서 시각화할 수 있습니다.

우리는 샘플 애플리케이션에 의해 생성된 리소스를 볼 것입니다. 환경 준비 중에 생성된 [RBAC 권한](https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions)이 있는 리소스만 볼 수 있다는 점에 유의하세요.

![인사이트](/img/resource-view/eks-overview.jpg)