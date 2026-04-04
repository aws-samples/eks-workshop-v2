---
title: "Secrets 관리"
sidebar_position: 40
tmdTranslationSourceHash: '597d45e341c83e4eb22c3b224aaa55a2'
---

[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)은 클러스터 운영자가 비밀번호, OAuth 토큰, ssh 키 등과 같은 민감한 정보의 배포를 관리하는 데 도움이 되는 리소스입니다. 이러한 Secret은 데이터 볼륨으로 마운트되거나 Pod 내의 컨테이너에 환경 변수로 노출될 수 있으며, 이를 통해 Pod 배포와 컨테이너화된 애플리케이션에 필요한 민감한 데이터 관리를 분리할 수 있습니다.

DevOps 팀이 다양한 Kubernetes 리소스에 대한 YAML 매니페스트를 관리하고 Git 리포지토리를 사용하여 버전 관리하는 것이 일반적인 관행이 되었습니다. 이를 통해 Git 리포지토리를 GitOps 워크플로우와 통합하여 EKS 클러스터에 이러한 리소스를 지속적으로 전달할 수 있습니다.
Kubernetes는 단순히 base64 인코딩을 사용하여 Secret의 민감한 데이터를 난독화하며, 이러한 파일을 Git 리포지토리에 저장하는 것은 base64로 인코딩된 데이터를 디코딩하는 것이 매우 간단하기 때문에 극도로 안전하지 않습니다. 이로 인해 클러스터 외부에서 Kubernetes Secret의 YAML 매니페스트를 관리하기가 어렵습니다.

Secrets 관리에 사용할 수 있는 몇 가지 다른 접근 방식이 있으며, 이 Secrets 관리 챕터에서는 그 중 몇 가지를 다룰 것입니다. [Sealed Secrets for Kubernetes](https://github.com/bitnami-labs/sealed-secrets)와 [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)를 살펴보겠습니다.

