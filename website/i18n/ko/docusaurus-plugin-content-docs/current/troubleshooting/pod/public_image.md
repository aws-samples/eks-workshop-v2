---
title: "ImagePullBackOff - 퍼블릭 이미지"
sidebar_position: 72
tmdTranslationSourceHash: '41d5d8121672805ce38786d2e304bdeb'
---

이 섹션에서는 ECR 퍼블릭 이미지에 대한 Pod ImagePullBackOff 오류를 트러블슈팅하는 방법을 배웁니다. 이제 배포가 생성되었는지 확인하여 시나리오 트러블슈팅을 시작할 수 있습니다.

```bash
$ kubectl get deployment ui-new -n default
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
ui-new   0/1     1            0           75s
```

:::info
동일한 출력을 얻었다면 트러블슈팅을 시작할 준비가 된 것입니다.
:::

이 트러블슈팅 섹션에서 여러분의 작업은 배포 ui-new가 0/1 준비 상태에 있는 원인을 찾고 이를 수정하여 배포가 하나의 Pod가 준비되고 실행되도록 하는 것입니다.

## 트러블슈팅 시작

### 1단계: Pod 상태 확인

먼저 `kubectl` 도구를 사용하여 Pod의 상태를 확인해야 합니다.

```bash
$ kubectl get pods -l app=app-new
NAME                      READY   STATUS             RESTARTS   AGE
ui-new-5654dd8969-7w98k   0/1     ImagePullBackOff   0          13s
```

### 2단계: Pod 상세 정보 확인

Pod 상태가 ImagePullBackOff로 표시되는 것을 볼 수 있습니다. Pod를 상세히 조회하여 이벤트를 확인해 보겠습니다.

```bash expectError=true timeout=20
$ POD=`kubectl get pods -l app=app-new -o jsonpath='{.items[*].metadata.name}'`
$ kubectl describe pod $POD | awk '/Events:/,/^$/'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  48s                default-scheduler  Successfully assigned default/ui-new-5654dd8969-7w98k to ip-10-42-33-232.us-west-2.compute.internal
  Normal   BackOff    23s (x2 over 47s)  kubelet            Back-off pulling image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1"
  Warning  Failed     23s (x2 over 47s)  kubelet            Error: ImagePullBackOff
  Normal   Pulling    12s (x3 over 47s)  kubelet            Pulling image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1"
  Warning  Failed     12s (x3 over 47s)  kubelet            Failed to pull image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": rpc error: code = NotFound desc = failed to pull and unpack image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": failed to resolve reference "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1: not found
  Warning  Failed     12s (x3 over 47s)  kubelet            Error: ErrImagePull
```

Pod의 이벤트에서 오류 코드 NotFound와 함께 "Failed to pull image" 경고를 볼 수 있습니다. 이는 Pod/배포 스펙에서 참조된 이미지가 해당 경로에서 찾을 수 없음을 나타냅니다.

### 3단계: 이미지 참조 확인

Pod가 사용하는 이미지를 확인해 보겠습니다.

```bash
$ kubectl get pod $POD -o jsonpath='{.spec.containers[*].image}'
public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1
```

이미지 URI에서 이미지가 AWS의 퍼블릭 ECR 리포지토리에서 참조되고 있음을 확인할 수 있습니다.

### 4단계: 이미지 존재 여부 확인

[aws-containers ECR](https://gallery.ecr.aws/aws-containers)에서 태그 1.2.1을 가진 retailing-store-sample-ui라는 이름의 이미지가 존재하는지 확인해 보겠습니다. "retailing-store-sample-ui"를 검색하면 그러한 이미지 리포지토리가 나타나지 않는다는 것을 알 수 있습니다. 브라우저에서 이미지 URI를 사용하여 퍼블릭 ECR에서 이미지 존재 여부를 쉽게 확인할 수도 있습니다. 이 경우 [image-uri](https://gallery.ecr.aws/aws-containers/retailing-store-sample-ui)는 "Repository not found" 메시지를 표시합니다.

![RepoDoesNotExist](/docs/troubleshooting/pod/rep-not-found.webp)

### 5단계: 올바른 이미지로 배포 업데이트

문제를 해결하려면 올바른 이미지 참조로 배포/Pod 스펙을 업데이트해야 합니다. 이 경우에는 public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1입니다.

#### 5.1. 이미지 존재 확인

배포를 업데이트하기 전에 위에서 언급한 방법, 즉 [image-uri](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)를 방문하여 이미지가 존재하는지 확인해 보겠습니다. 1.2.1을 포함한 여러 태그가 있는 retail-store-sample-ui 이미지를 볼 수 있어야 합니다.

![RepoExist](/docs/troubleshooting/pod/repo-found.webp)

#### 5.1. 올바른 참조로 배포의 이미지 업데이트

```bash
$ kubectl patch deployment ui-new --patch '{"spec": {"template": {"spec": {"containers": [{"name": "ui", "image": "public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1"}]}}}}'
deployment.apps/ui-new patched
```

### 6단계: 수정 확인

새 Pod가 생성되고 성공적으로 실행되는지 확인합니다.

```bash timeout=180 hook=fix-1 hookTimeout=600 wait=20
$ kubectl get pods -l app=app-new
NAME                     READY   STATUS    RESTARTS   AGE
ui-new-77856467b-2z2s6   1/1     Running   0          13s
```

## 정리

퍼블릭 이미지의 ImagePullBackOff가 발생한 Pod의 일반적인 트러블슈팅 워크플로우는 다음과 같습니다:

- "not found", "access denied" 또는 "timeout"과 같은 문제의 원인에 대한 단서를 얻기 위해 Pod 이벤트를 확인합니다.
- "not found"인 경우 참조된 경로에 이미지가 존재하는지 확인합니다.
- "access denied"인 경우 워커 노드 역할의 권한을 확인합니다.
- ECR의 퍼블릭 이미지에 대한 timeout인 경우 워커 노드 네트워킹이 IGW/TGW/NAT를 통해 인터넷에 도달하도록 구성되어 있는지 확인합니다.

