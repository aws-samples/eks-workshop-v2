---
title: "GitOps"
sidebar_position: 2
weight: 20
tmdTranslationSourceHash: 'bffd2f294faa49e347acd006bd1b4256'
---

기업들은 빠르게 움직이고자 합니다. 더 자주, 더 안정적으로, 그리고 가능하면 더 적은 오버헤드로 배포해야 합니다. GitOps는 개발자가 Kubernetes에서 실행되는 복잡한 애플리케이션과 인프라를 관리하고 업데이트할 수 있는 빠르고 안전한 방법입니다.

GitOps는 클라우드 네이티브 애플리케이션을 위한 인프라 및 배포를 관리하기 위한 운영 및 애플리케이션 배포 워크플로이자 모범 사례 집합입니다. 이 게시물은 두 부분으로 나뉩니다. 첫 번째 부분에서는 GitOps의 역사와 작동 방식, 그리고 이점에 대해 설명합니다. 두 번째 부분에서는 Flux를 사용하여 Amazon Elastic Kubernetes Service(Amazon EKS)에 지속적 배포 파이프라인을 설정하는 방법을 설명하는 실습 튜토리얼을 통해 직접 시도해 볼 수 있습니다.

GitOps란 무엇인가요? Weaveworks CEO인 Alexis Richardson가 만든 용어인 GitOps는 Kubernetes 및 기타 클라우드 네이티브 기술을 위한 운영 모델입니다. 클러스터 및 애플리케이션의 배포, 관리, 모니터링을 통합하는 모범 사례 집합을 제공합니다. 다르게 표현하면, 애플리케이션 관리를 위한 개발자 경험으로 가는 길이며, 엔드투엔드 CI 및 CD 파이프라인과 Git 워크플로가 운영과 개발 모두에 적용되는 것입니다.

모듈 관리자 중 한 명인 Carlos Santana(AWS)와 함께 GitOps 섹션의 동영상 안내를 시청하세요:

<ReactPlayer controls src="https://www.youtube-nocookie.com/embed/dONzzCc0oHo" width={640} height={360} /> <br />

