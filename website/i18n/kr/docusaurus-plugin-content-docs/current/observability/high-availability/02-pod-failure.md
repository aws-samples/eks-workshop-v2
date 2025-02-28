---
title: "Pod 장애 시뮬레이션"
sidebar_position: 110
description: "ChaosMesh를 사용하여 환경에서 pod 장애를 시뮬레이션하여 애플리케이션의 복원력을 테스트합니다."
---

## 개요

이 실습에서는 Kubernetes 환경 내에서 pod 장애를 시뮬레이션하여 시스템이 어떻게 응답하고 복구되는지 관찰할 것입니다. 이 실험은 pod가 예기치 않게 실패할 때 특히 애플리케이션의 복원력을 테스트하도록 설계되었습니다.

`pod-failure.sh` 스크립트는 Kubernetes용 강력한 카오스 엔지니어링 플랫폼인 Chaos Mesh를 활용하여 pod 장애를 시뮬레이션합니다. 이 제어된 실험을 통해 다음을 수행할 수 있습니다:

1. pod 장애에 대한 시스템의 즉각적인 응답 관찰
2. 자동 복구 프로세스 모니터링
3. 시뮬레이션된 장애에도 불구하고 애플리케이션이 사용 가능한 상태로 유지되는지 확인

이 실험은 반복 가능하여 일관된 동작을 보장하고 다양한 시나리오나 구성을 테스트하기 위해 여러 번 실행할 수 있습니다. 다음은 우리가 사용할 스크립트입니다:

```file
manifests/modules/observability/resiliency/scripts/pod-failure.sh
```

## 실험 실행하기

## 단계 1: 초기 Pod 상태 확인

먼저, `ui` 네임스페이스에서 pod들의 초기 상태를 확인해보겠습니다:

```bash
$ kubectl get pods -n ui -o wide
```

다음과 같은 출력이 표시되어야 합니다:

```text
NAME                  READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          46s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          46s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          46s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-qqltz   1/1     Running   0          46s   10.42.185.149   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          46s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
```

모든 pod가 비슷한 시작 시간(AGE 열에 표시)을 가지고 있음을 주목하세요.

### 단계 2: Pod 장애 시뮬레이션

이제 pod 장애를 시뮬레이션해보겠습니다:

```bash
$ ~/$SCRIPT_DIR/pod-failure.sh
```

이 스크립트는 Chaos Mesh를 사용하여 pod 중 하나를 종료시킬 것입니다.

### 단계 3: 복구 관찰

Kubernetes가 장애를 감지하고 복구를 시작할 수 있도록 몇 초 기다립니다. 그런 다음 pod 상태를 다시 확인합니다:

```bash timeout=5
$ kubectl get pods -n ui -o wide
```

이제 다음과 같은 출력이 표시되어야 합니다:

```text
NAME                  READY   STATUS    RESTARTS   AGE     IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          2m57s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          2m57s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-ghp5z   1/1     Running   0          6s      10.42.185.150   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          2m57s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          2m57s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
[ec2-user@bc44085aafa9 environment]$
```

pod 중 하나(이 예에서는 `ui-6dfb84cf67-ghp5z`)의 AGE 값이 훨씬 낮은 것을 확인할 수 있습니다. 이는 시뮬레이션에 의해 종료된 pod를 대체하기 위해 Kubernetes가 자동으로 생성한 pod입니다.

이는 `ui` 네임스페이스의 각 pod에 대한 상태, IP 주소 및 노드를 보여줄 것입니다.

## 리테일 스토어 가용성 확인

이 실험의 중요한 측면은 pod 장애 및 복구 프로세스 전반에 걸쳐 리테일 스토어 애플리케이션이 계속 작동하는지 확인하는 것입니다. 리테일 스토어의 가용성을 확인하려면 다음 명령을 사용하여 스토어의 URL을 가져와 접근하세요:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

준비가 되면 이 URL을 통해 리테일 스토어에 접속하여 시뮬레이션된 pod 장애에도 불구하고 여전히 제대로 작동하는지 확인할 수 있습니다.

## 결론

이 pod 장애 시뮬레이션은 Kubernetes 기반 애플리케이션의 복원력을 보여줍니다. 의도적으로 pod를 실패하게 함으로써 다음을 관찰할 수 있습니다:

1. 시스템의 신속한 장애 감지 능력
2. Kubernetes의 자동 재스케줄링 및 Deployment 또는 StatefulSet의 실패한 pod 복구
3. pod 장애 중에도 애플리케이션의 지속적인 가용성

리테일 스토어는 pod가 실패하더라도 계속 작동해야 하며, 이는 Kubernetes 설정의 고가용성과 장애 허용성을 보여줍니다. 이 실험은 애플리케이션의 복원력을 검증하는 데 도움이 되며, 다양한 시나리오에서 또는 인프라를 변경한 후에도 일관된 동작을 보장하기 위해 필요에 따라 반복할 수 있습니다.

이러한 카오스 엔지니어링 실험을 정기적으로 수행함으로써, 시스템이 다양한 유형의 장애를 견디고 복구할 수 있는 능력에 대한 신뢰를 구축할 수 있으며, 궁극적으로 더 강력하고 신뢰할 수 있는 애플리케이션을 만들 수 있습니다.