---
title: 시작하기
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 워크로드 실행의 기본을 배웁니다."
tmdTranslationSourceHash: 7cdfb6c9bfdda46e240ba735baaedb14
---

::required-time

EKS 워크샵의 첫 번째 실습에 오신 것을 환영합니다. 이 실습의 목표는 앞으로 진행할 많은 실습 과정에서 사용할 샘플 애플리케이션에 익숙해지는 것이며, 이를 통해 EKS에 워크로드를 배포하는 것과 관련된 몇 가지 기본 개념을 다룰 것입니다. 애플리케이션의 아키텍처를 살펴보고 구성 요소들을 EKS 클러스터에 배포할 것입니다.

실습 환경의 EKS 클러스터에 첫 번째 워크로드를 배포하고 탐색해 봅시다!

시작하기 전에 다음 명령을 실행하여 IDE 환경과 EKS 클러스터를 준비해야 합니다:

```bash
$ prepare-environment introduction/getting-started
```

이 명령은 무엇을 하는 걸까요? 이번 실습에서는 필요한 Kubernetes 매니페스트 파일이 파일 시스템에 존재하도록 EKS Workshop Git 리포지토리를 IDE 환경에 클론합니다.

이후 실습에서도 이 명령을 실행하게 되는데, 다음 두 가지 중요한 추가 기능을 수행합니다:

1. EKS 클러스터를 초기 상태로 재설정
2. 다가오는 실습 과정에 필요한 추가 구성 요소를 클러스터에 설치

