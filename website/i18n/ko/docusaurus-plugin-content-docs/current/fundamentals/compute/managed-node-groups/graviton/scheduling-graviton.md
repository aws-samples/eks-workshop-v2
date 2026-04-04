---
title: Graviton에서 Pod 실행
sidebar_position: 20
tmdTranslationSourceHash: '375c541b385540f699ead3b7a4a1bf03'
---

이제 Graviton 노드 그룹에 taint를 적용했으므로, 이 변경 사항을 활용하도록 애플리케이션을 구성해야 합니다. 이를 위해 Graviton 기반 관리형 노드 그룹에 속한 노드에만 `ui` 마이크로서비스를 배포하도록 애플리케이션을 구성하겠습니다.

변경을 수행하기 전에 UI Pod의 현재 구성을 확인해 보겠습니다. 이러한 Pod는 `ui`라는 이름의 관련 배포에 의해 제어되고 있다는 점을 기억하세요.

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

예상대로 애플리케이션은 taint가 적용되지 않은 노드에서 성공적으로 실행되고 있습니다. 관련 Pod는 `Running` 상태이며 사용자 정의 toleration이 구성되지 않았음을 확인할 수 있습니다. Kubernetes는 사용자나 컨트롤러가 명시적으로 설정하지 않는 한 `node.kubernetes.io/not-ready` 및 `node.kubernetes.io/unreachable`에 대해 `tolerationSeconds=300`으로 toleration을 자동으로 추가합니다. 이러한 자동으로 추가된 toleration은 이러한 문제 중 하나가 감지된 후 5분 동안 Pod가 노드에 바인딩된 상태로 유지됨을 의미합니다.

`ui` 배포를 업데이트하여 해당 Pod를 taint가 적용된 관리형 노드 그룹에 바인딩하겠습니다. taint가 적용된 관리형 노드 그룹은 `nodeSelector`와 함께 사용할 수 있는 `tainted=yes` 레이블로 사전 구성되어 있습니다. 다음 `Kustomize` 패치는 이 설정을 활성화하기 위해 배포 구성에 필요한 변경 사항을 설명합니다:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```
위 매니페스트에서 `nodeSelector`는 `kubernetes.io/arch: arm64` 레이블이 있는 노드에만 Pod가 스케줄링되어야 함을 지정합니다. 이 `nodeSelector`는 UI Pod를 ARM64 아키텍처 노드(Graviton 노드)에서만 실행되도록 효과적으로 제한합니다.

Kustomize 변경 사항을 적용하려면 다음 명령을 실행하세요:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

최근 변경 사항을 적용한 후 UI 배포의 롤아웃 상태를 확인해 보겠습니다:

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

`ui` 배포의 기본 `RollingUpdate` 전략이 주어지면, K8s 배포는 새로 생성된 Pod가 `Ready` 상태가 될 때까지 기다린 후 이전 Pod를 종료합니다. 배포 롤아웃이 멈춘 것 같으니 더 자세히 조사해 보겠습니다:

```bash hook=pending-pod
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

`ui` 네임스페이스 아래의 개별 Pod를 조사하면 하나의 Pod가 `Pending` 상태임을 관찰할 수 있습니다. `Pending` Pod의 세부 정보를 더 자세히 살펴보면 발생한 문제에 대한 정보를 얻을 수 있습니다.

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

변경 사항이 `Pending` Pod의 새 구성에 반영되어 있습니다. `tainted=yes` 레이블이 있는 모든 노드에 Pod를 고정했지만 Pod를 스케줄링할 수 없어(`PodScheduled False`) 새로운 문제가 발생했습니다. 더 유용한 설명은 `events`에서 찾을 수 있습니다:

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

이 문제를 해결하려면 toleration을 추가해야 합니다. 배포 및 관련 Pod가 `frontend: true` taint를 tolerate할 수 있도록 해야 합니다. 아래 `kustomize` 패치를 사용하여 필요한 변경을 수행할 수 있습니다:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```
이 YAML은 toleration을 추가하여 이전 구성을 기반으로 합니다. `tolerations` 섹션은 아래 설명과 같이 `frontend` taint가 있는 노드에 Pod를 스케줄링할 수 있도록 합니다:
- `key: "frontend"`는 tolerate할 taint 키를 지정합니다.
- `operator: "Exists"`는 값에 관계없이 Pod가 taint를 tolerate함을 의미합니다.
- `effect: "NoExecute"`는 taint 효과와 일치하여 이 taint가 있는 노드에서 Pod가 실행될 수 있도록 합니다.

nodeSelector는 동일하게 유지되어 Pod가 ARM64 아키텍처 노드에서만 실행되도록 보장합니다. Kustomize 변경 사항을 적용하려면 다음 명령을 실행하세요:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

UI Pod를 확인하면 이제 구성에 지정된 toleration(`frontend=true:NoExecute`)이 포함되어 있고 해당 taint가 있는 노드에 성공적으로 스케줄링되었음을 알 수 있습니다. 다음 명령을 사용하여 검증할 수 있습니다:

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

보시다시피, `ui` Pod는 이제 Graviton 기반 노드 그룹에서 실행되고 있습니다. 또한 `kubectl describe node` 명령에서 Taint를, `kubectl describe pod` 명령에서 일치하는 Toleration을 확인할 수 있습니다.

Intel과 ARM 기반 프로세서 모두에서 실행할 수 있는 `ui` 애플리케이션을 이전 단계에서 생성한 새 Graviton 기반 관리형 노드 그룹에서 실행되도록 성공적으로 스케줄링했습니다. Taint와 toleration은 Graviton/GPU 강화 노드용이든 멀티 테넌트 Kubernetes 클러스터용이든, Pod가 노드에 스케줄링되는 방법을 구성하는 데 사용할 수 있는 강력한 도구입니다.

