---
title: 임시 컨테이너 스토리지
sidebar_position: 10
---
이 섹션에서는 간단한 이미지 호스팅 예제를 통해 Kubernetes 배포에서 스토리지를 처리하는 방법을 살펴보겠습니다. 샘플 스토어 애플리케이션의 기존 배포로 시작하여 이미지 호스트 역할을 하도록 수정할 것입니다. `assets` 마이크로서비스는 EKS에서 웹 서버를 실행하며,**수평적 확장**과 Pod의**선언적 상태 관리**가 가능하기 때문에 배포를 시연하기에 훌륭한 예시입니다.

`assets` 컴포넌트는 컨테이너에서 정적 제품 이미지를 제공합니다. 이러한 이미지들은 빌드 과정 중에 컨테이너에 번들로 포함됩니다. 하지만 이 접근 방식에는 한계가 있습니다 - 한 컨테이너에 새로운 이미지가 추가되어도 다른 컨테이너에는 자동으로 나타나지 않습니다. 이를 해결하기 위해 [Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)와 Kubernetes [영구 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 사용하여 공유 스토리지 환경을 만들 것입니다. 이를 통해 여러 웹 서버 컨테이너가 수요에 맞춰 확장하면서 `assets`을 제공할 수 있습니다.

현재 배포의 볼륨 구성을 살펴보겠습니다:

```bash
$ kubectl describe deployment -n assets
Name:                   assets
Namespace:              assets
[...]
  Containers:
   assets:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-assets:0.4.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  128Mi
    Requests:
      cpu:     128m
      memory:  128Mi
    Liveness:  http-get http://:8080/health.html delay=0s timeout=1s period=3s #success=1 #failure=3
    Environment Variables from:
      assets      ConfigMap  Optional: false
    Environment:  <none>
    Mounts:
      /tmp from tmp-volume (rw)
  Volumes:
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) 섹션을 보면, 현재 배포가 Pod의 수명 동안만 존재하는 [EmptyDir 볼륨 타입](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)을 사용하고 있음을 알 수 있습니다.

![Assets with emptyDir](./assets/assets-emptydir.webp)

`emptyDir` 볼륨은 Pod가 노드에 할당될 때 생성되며 해당 Pod가 해당 노드에서 실행되는 동안에만 유지됩니다. 이름에서 알 수 있듯이, 볼륨은 비어있는 상태로 시작됩니다. Pod 내의 모든 컨테이너가 `emptyDir` 볼륨의 파일을 읽고 쓸 수 있지만(다른 경로에 마운트되어 있더라도), **어떤 이유로든 노드에서 Pod가 제거되면 `emptyDir`의 데이터는 영구적으로 삭제됩니다.** 이는 데이터가 지속되어야 하는 경우 동일한 배포의 여러 Pod 간에 데이터를 공유하는 데 `emptyDir`가 적합하지 않다는 것을 의미합니다.

컨테이너에는 빌드 과정 중에 `/usr/share/nginx/html/assets`에 복사된 초기 제품 이미지가 포함되어 있습니다. 다음 명령으로 이를 확인할 수 있습니다:

```bash
$ kubectl exec --stdin deployment/assets \
  -n assets -- bash -c "ls /usr/share/nginx/html/assets/"
chrono_classic.jpg
gentleman.jpg
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
wood_watch.jpg
```

EmptyDir 스토리지의 한계를 보여주기 위해 `assets` 배포를 여러 복제본으로 확장해보겠습니다:

```bash
$ kubectl scale -n assets --replicas=2 deployment/assets
deployment.apps/assets scaled

$ kubectl rollout status -n assets deployment/assets --timeout=60s
deployment "assets" successfully rolled out
```

이제 첫 번째 Pod의 `/usr/share/nginx/html/assets` 디렉토리에 `divewatch.png`라는 새로운 제품 이미지를 추가하고 존재하는지 확인해보겠습니다:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -- bash -c 'touch /usr/share/nginx/html/assets/divewatch.jpg'
$ kubectl exec --stdin $POD_NAME \
  -n assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
divewatch.jpg <-----------
gentleman.jpg
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
wood_watch.jpg
```

두 번째 Pod에서 새로운 제품 이미지 `divewatch.jpg`가 나타나는지 확인해보겠습니다:

```bash
$ POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_NAME \
  -n assets -- bash -c 'ls /usr/share/nginx/html/assets'
chrono_classic.jpg
gentleman.jpg
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
wood_watch.jpg
```

보시다시피 `divewatch.jpg`는 두 번째 Pod에 존재하지 않습니다. 이는 수평적으로 확장할 때 여러 Pod에 걸쳐 지속되며 재배포 없이 파일 업데이트를 허용하는 공유 파일시스템이 필요한 이유를 보여줍니다.
