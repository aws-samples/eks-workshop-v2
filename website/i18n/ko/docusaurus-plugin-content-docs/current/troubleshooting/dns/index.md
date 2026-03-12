---
title: "DNS 해결"
sidebar_position: 60
chapter: true
sidebar_custom_props: { "module": true }
description: "DNS 해결 문제로 인해 서비스 통신이 중단되었습니다."
tmdTranslationSourceHash: 'c92393711351c854b411e33abe38f6cd'
---

::required-time

이 실습에서는 서비스 통신이 중단되는 시나리오를 조사합니다. 네트워킹 문제를 해결하고 근본 원인이 DNS 해결과 관련이 있음을 확인합니다. 그런 다음 다양한 유형의 DNS 해결 실패를 진단하고, 수정 사항을 구현하며, 서비스 통신을 복원하기 위한 필수 문제 해결 단계를 살펴봅니다. EKS의 DNS 문제 해결에 대한 추가 정보는 [Amazon EKS에서 DNS 실패를 해결하려면 어떻게 해야 합니까?](https://repost.aws/knowledge-center/eks-dns-failure)를 참조하세요.

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=900 wait=10
$ prepare-environment troubleshooting/dns
```

이 모듈의 prepare-environment 스크립트는 워크샵 환경을 재설정합니다.
:::

### EKS의 DNS 해결

EKS 클러스터에서 애플리케이션이 다른 서비스(클러스터 내부 또는 외부)에 연결해야 할 때, DNS를 통해 대상 엔드포인트 이름을 IP 주소로 해결해야 합니다.

기본적으로 Kubernetes 클러스터는 모든 Pod가 kube-dns 서비스 ClusterIP 주소를 네임 서버로 사용하도록 구성합니다. Amazon EKS 클러스터를 시작하면 EKS는 kube-dns 서비스 뒤에서 제공할 CoreDNS의 두 개의 Pod 복제본을 배포합니다.

[CoreDNS](https://coredns.io/)는 표준 Kubernetes 클러스터 DNS로 널리 채택된 유연하고 확장 가능한 DNS 서버입니다.

다음 섹션에서 문제 해결 여정을 시작하겠습니다.

