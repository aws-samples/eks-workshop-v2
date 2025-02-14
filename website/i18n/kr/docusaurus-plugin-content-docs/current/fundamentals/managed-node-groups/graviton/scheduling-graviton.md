---
title: 그라비톤 위에 Pod 실행
sidebar_position: 20
---
이제 Graviton 노드 그룹에 테인트를 적용했으니, 이 변경사항을 활용하도록 애플리케이션을 구성해야 합니다. 이를 위해 `ui` 마이크로서비스가 Graviton 기반 관리형 노드 그룹에 속한 노드에서만 배포되도록 애플리케이션을 구성해 보겠습니다.

변경하기 전에, UI 파드의 현재 구성을 확인해 보겠습니다. 이 파드들은 `ui`라는 이름의 배포(deployment)에 의해 제어되고 있다는 점을 기억하세요.

```bash
$ kubectl describe pod --namespace ui --selector app.kubernetes.io/name=ui
Name:             ui-7bdbf967f9-qzh7f
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-11-43.us-west-2.compute.internal/10.42.11.43
Start Time:       Wed, 09 Nov 2022 16:40:32 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=7bdbf967f9
Status:           Running
[....]
Controlled By:  ReplicaSet/ui-7bdbf967f9
Containers:
[...]
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```

예상대로 애플리케이션이 테인트가 없는 노드에서 정상적으로 실행되고 있습니다. 관련 파드는 `Running` 상태이며 사용자 정의 톨러레이션이 구성되어 있지 않음을 확인할 수 있습니다. Kubernetes는 사용자나 컨트롤러가 명시적으로 톨러레이션을 설정하지 않는 한, `node.kubernetes.io/not-ready`와 `node.kubernetes.io/unreachable`에 대해 `tolerationSeconds=300`인 톨러레이션을 자동으로 추가합니다. 이러한 자동 추가된 톨러레이션은 이러한 문제가 감지된 후 5분 동안 파드가 노드에 바인딩된 상태로 유지됨을 의미합니다.

테인트된 관리형 노드 그룹에 파드를 바인딩하도록 `ui` 배포를 업데이트해 보겠습니다. 우리는 `nodeSelector`와 함께 사용할 수 있는 `tainted=yes` 레이블로 테인트된 관리형 노드 그룹을 미리 구성했습니다. 다음 `Kustomize` 패치는 이 설정을 활성화하기 위해 배포 구성에 필요한 변경사항을 설명합니다:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```

Kustomize 변경사항을 적용하려면 다음 명령을 실행하세요:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

최근 변경사항을 적용했으니 UI 배포의 롤아웃 상태를 확인해 보겠습니다:

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

`ui` 배포의 기본 `RollingUpdate` 전략으로 인해, K8s 배포는 이전 파드를 종료하기 전에 새로 생성된 파드가 `Ready` 상태가 될 때까지 기다립니다. 배포 롤아웃이 멈춘 것 같으니 더 자세히 살펴보겠습니다:

```bash
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

`ui` 네임스페이스의 개별 파드를 조사해보면 하나의 파드가 `Pending` 상태인 것을 확인할 수 있습니다. `Pending` 파드의 세부 정보를 더 자세히 살펴보면 발생한 문제에 대한 정보를 얻을 수 있습니다.

```bash
$ podname=$(kubectl get pod --namespace ui --field-selector=status.phase=Pending -o json | \
                jq -r '.items[0].metadata.name') && \
                kubectl describe pod $podname -n ui
Name:           ui-659df48c56-z496x
Namespace:      ui
[...]
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  19s   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

새 구성에서 우리의 변경사항이 반영되었습니다. `tainted=yes` 레이블이 있는 노드에 파드를 고정했지만, 파드를 스케줄링할 수 없는 (`PodScheduled False`) 새로운 문제가 발생했습니다. `events`에서 더 유용한 설명을 찾을 수 있습니다:

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

이를 해결하기 위해 톨러레이션을 추가해야 합니다. 배포와 관련 파드가 `frontend: true` 테인트를 허용할 수 있도록 합시다. 필요한 변경을 하기 위해 아래의 `kustomize` 패치를 사용할 수 있습니다:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

UI 파드를 확인해보면, 지정된 톨러레이션(`frontend=true:NoExecute`)이 구성에 포함되어 있고 해당 테인트가 있는 노드에 성공적으로 스케줄링된 것을 볼 수 있습니다. 다음 명령어로 검증할 수 있습니다:

```bash
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6c5c9f6b5f-7jxp8   1/1     Running   0          29s
```

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:         ui-6c5c9f6b5f-7jxp8
Namespace:    ui
Priority:     0
Node:         ip-10-42-10-138.us-west-2.compute.internal/10.42.10.138
Start Time:   Fri, 11 Nov 2022 13:00:36 +0000
Labels:       app.kubernetes.io/component=service
              app.kubernetes.io/created-by=eks-workshop
              app.kubernetes.io/instance=ui
              app.kubernetes.io/name=ui
              pod-template-hash=6c5c9f6b5f
Annotations:  kubernetes.io/psp: eks.privileged
              prometheus.io/path: /actuator/prometheus
              prometheus.io/port: 8080
              prometheus.io/scrape: true
Status:       Running
IP:           10.42.10.225
IPs:
  IP:           10.42.10.225
Controlled By:  ReplicaSet/ui-6c5c9f6b5f
Containers:
  [...]
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
[...]
QoS Class:                   Burstable
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 frontend:NoExecute op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
[...]
```

```bash
$ kubectl describe node --selector kubernetes.io/arch=arm64
Name:               ip-10-42-10-138.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-03e8f91597dcf297b
                    kubernetes.io/arch=arm64
                    kubernetes.io/hostname=ip-10-42-10-138.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=t4g.medium
[...]
Taints:             frontend=true:NoExecute
Unschedulable:      false
[...]
```

보시다시피 `ui` 파드가 이제 Graviton 기반 노드 그룹에서 실행되고 있습니다. 또한 `kubectl describe node` 명령에서 테인트를, `kubectl describe pod` 명령에서 일치하는 톨러레이션을 확인할 수 있습니다.

이전 단계에서 생성한 새로운 Graviton 기반 관리형 노드 그룹에서 Intel과 ARM 기반 프로세서 모두에서 실행될 수 있는 `ui` 애플리케이션을 성공적으로 스케줄링했습니다. 테인트와 톨러레이션은 Graviton/GPU 강화 노드나, 멀티 테넌트 Kubernetes 클러스터를 위해 파드가 노드에 스케줄링되는 방식을 구성하는 데 사용할 수 있는 강력한 도구입니다.
