---
title: "Sealed Secrets를 사용한 시크릿 보안"
sidebar_position: 430
sidebar_custom_props: { "module": true }
description: "Sealed Secrets를 사용하여 Amazon Elastic Kubernetes Service(EKS)에서 실행되는 애플리케이션에 자격 증명과 같은 민감한 구성을 제공합니다."
---

::required-time

:::caution
[Sealed Secrets](https://docs.bitnami.com/tutorials/sealed-secrets) 프로젝트는 AWS 서비스와 관련이 없으며 [Bitnami Labs](https://bitnami.com/)의 서드파티 오픈소스 도구입니다
:::

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment security/sealed-secrets
```

:::

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)는 Secret 객체를 암호화하여 공개 리포지토리에도 안전하게 저장할 수 있는 메커니즘을 제공합니다. SealedSecret은 Kubernetes 클러스터에서 실행되는 컨트롤러만이 복호화할 수 있으며, 다른 누구도 SealedSecret으로부터 원본 Secret을 얻을 수 없습니다.

이 장에서는 SealedSecrets를 사용하여 Kubernetes Secrets와 관련된 YAML 매니페스트를 암호화하고, [kubectl](https://kubernetes.io/docs/reference/kubectl/)과 같은 도구를 사용하는 일반적인 워크플로우를 통해 이러한 암호화된 Secrets를 EKS 클러스터에 배포하는 방법을 배우게 됩니다.