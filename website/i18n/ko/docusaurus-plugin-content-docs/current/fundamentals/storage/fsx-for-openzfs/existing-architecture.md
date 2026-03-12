---
title: "기존 아키텍처"
sidebar_position: 10
tmdTranslationSourceHash: '4221ca348cec93455134b8785dbef650'
---

이 섹션에서는 간단한 이미지 호스팅 예제를 사용하여 Kubernetes 배포에서 스토리지를 처리하는 방법을 살펴보겠습니다. 샘플 스토어 애플리케이션의 기존 배포로 시작하여 이를 이미지 호스트로 작동하도록 수정할 것입니다. UI 컴포넌트는 상태 비저장 마이크로서비스로, Pod의 **수평적 확장**과 **선언적 상태 관리**를 가능하게 하므로 배포를 시연하기에 탁월한 예제입니다.

UI 컴포넌트의 역할 중 하나는 정적 제품 이미지를 제공하는 것입니다. 현재 이러한 이미지는 빌드 프로세스 중에 컨테이너에 번들로 포함됩니다. 그러나 이 접근 방식에는 상당한 제약이 있습니다 - 컨테이너가 배포된 후에는 새 이미지를 추가할 수 없습니다. 이러한 제약을 해결하기 위해 [Amazon FSx for OpenZFS](https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/what-is-fsx.html)와 Kubernetes [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 사용하여 공유 스토리지 환경을 구축하는 솔루션을 구현할 것입니다. 이를 통해 여러 웹 서버 컨테이너가 자산을 제공하면서 수요에 맞춰 동적으로 확장할 수 있습니다.

현재 Deployment의 볼륨 구성을 살펴보겠습니다:

```bash
$ kubectl describe deployment -n ui
Name:                   ui
Namespace:              ui
[...]
  Containers:
   ui:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  1536Mi
    Requests:
      cpu:     250
      memory:  1536Mi
    [...]
    Mounts:
      /tmp from tmp-volume (rw)
  Volumes:
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) 섹션을 보면, Deployment가 현재 Pod의 수명 동안만 존재하는 [EmptyDir 볼륨 타입](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)을 사용하고 있음을 알 수 있습니다. 이는 Pod가 종료되면 이 볼륨에 저장된 데이터가 영구적으로 손실된다는 것을 의미합니다.

그러나 UI 컴포넌트의 경우, 제품 이미지는 현재 Spring Boot를 통해 [정적 웹 콘텐츠](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)로 제공되고 있으므로, 이미지가 파일 시스템에 존재하지 않습니다.

