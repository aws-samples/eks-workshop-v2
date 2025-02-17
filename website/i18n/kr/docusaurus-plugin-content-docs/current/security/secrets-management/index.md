---
title: "시크릿 관리"
sidebar_position: 40
---

[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)은 클러스터 운영자가 비밀번호, OAuth 토큰, ssh 키 등과 같은 민감한 정보의 배포를 관리하는 데 도움이 되는 리소스입니다. 이러한 시크릿은 Pod의 컨테이너에 데이터 볼륨으로 마운트되거나 환경 변수로 노출될 수 있어, Pod 배포와 Pod 내 컨테이너화된 애플리케이션에 필요한 민감한 데이터 관리를 분리할 수 있습니다.

DevOps 팀이 다양한 Kubernetes 리소스에 대한 YAML 매니페스트를 관리하고 Git 저장소를 사용하여 버전 관리하는 것이 일반적인 관행이 되었습니다. 이를 통해 Git 저장소를 GitOps 워크플로우와 통합하여 이러한 리소스를 EKS 클러스터에 지속적으로 배포할 수 있습니다.
Kubernetes는 단순한 base64 인코딩을 사용하여 Secret의 민감한 데이터를 난독화하지만, 이러한 파일을 Git 저장소에 저장하는 것은 base64로 인코딩된 데이터를 쉽게 디코딩할 수 있기 때문에 매우 안전하지 않습니다. 이로 인해 클러스터 외부에서 Kubernetes Secrets에 대한 YAML 매니페스트를 관리하기가 어렵습니다.

시크릿 관리를 위해 사용할 수 있는 몇 가지 다른 접근 방식이 있습니다. 이 시크릿 관리 장에서는 [Sealed Secrets for Kubernetes](https://github.com/bitnami-labs/sealed-secrets)와 [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)와 같은 몇 가지 방법을 다룰 것입니다.