---
title: 시작하기
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 워크로드를 실행하는 기본 사항을 학습합니다."
---

::required-time

EKS 워크샵의 첫 번째 실습에 오신 것을 환영합니다. 이 실습의 목표는 앞으로 진행될 많은 실습에서 사용할 샘플 애플리케이션에 익숙해지고, EKS에 워크로드를 배포하는 것과 관련된 기본 개념을 다루는 것입니다. 애플리케이션의 아키텍처를 살펴보고 EKS 클러스터에 컴포넌트들을 배포할 것입니다.

실습 환경의 EKS 클러스터에 첫 번째 워크로드를 배포하고 탐색해보겠습니다!

시작하기 전에 IDE 환경과 EKS 클러스터를 준비하기 위해 다음 명령을 실행해야 합니다:

```bash
$ prepare-environment introduction/getting-started
```

이 명령은 무엇을 하는 걸까요? 이 실습에서는 필요한 Kubernetes 매니페스트 파일들이 파일 시스템에 존재하도록 EKS Workshop Git 저장소를 IDE 환경에 클론합니다.

이후 실습에서도 이 명령을 실행할 것인데, 여기서는 두 가지 중요한 추가 기능을 수행합니다:

1. EKS 클러스터를 초기 상태로 재설정
2. 다음 실습에 필요한 추가 컴포넌트들을 클러스터에 설치