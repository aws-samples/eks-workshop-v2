---
title: "FIS 없이 노드 장애 시뮬레이션하기"
sidebar_position: 130
description: "AWS FIS를 사용하지 않고 Kubernetes 환경에서 수동으로 노드 장애를 시뮬레이션하여 애플리케이션의 복원력을 테스트합니다."
---

## 개요

이 실험은 Kubernetes 클러스터에서 수동으로 노드 장애를 시뮬레이션하여 배포된 애플리케이션, 특히 리테일 스토어 애플리케이션의 가용성에 미치는 영향을 이해합니다. 의도적으로 노드 장애를 발생시켜 Kubernetes가 장애를 어떻게 처리하고 클러스터의 전반적인 상태를 유지하는지 관찰할 수 있습니다.

`node-failure.sh` 스크립트는 노드 장애를 시뮬레이션하기 위해 EC2 인스턴스를 수동으로 중지합니다. 다음은 사용할 스크립트입니다:

```file
manifests/modules/observability/resiliency/scripts/node-failure.sh
```

이 실험은 반복 가능하다는 점이 중요합니다. 일관된 동작을 보장하고 다양한 시나리오나 구성을 테스트하기 위해 여러 번 실행할 수 있습니다.

## 실험 실행하기

노드 장애를 시뮬레이션하고 그 영향을 모니터링하려면 다음 명령을 실행하세요:

```bash timeout=240
$ ~/$SCRIPT_DIR/node-failure.sh && timeout --preserve-status 180s  ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-dsp55   1/1   Running   0     10m
       ui-6dfb84cf67-gzd9s   1/1   Running   0     8m19s

------us-west-2b------
  ip-10-42-133-195.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-4bmjm   1/1   Running   0     44s
       ui-6dfb84cf67-n8x4f   1/1   Running   0     10m
       ui-6dfb84cf67-wljth   1/1   Running   0     10m
```

이 명령은 선택된 EC2 인스턴스를 중지하고 2분 동안 파드 분배를 모니터링하여 시스템이 워크로드를 어떻게 재분배하는지 관찰합니다.

실험 중에는 다음과 같은 일련의 이벤트가 관찰되어야 합니다:

1. 약 1분 후, 목록에서 하나의 노드가 사라지는 것을 볼 수 있습니다. 이는 시뮬레이션된 노드 장애를 나타냅니다.
2. 노드 장애 직후, 파드들이 남아있는 정상 노드들로 재분배되는 것을 볼 수 있습니다. Kubernetes는 노드 장애를 감지하고 영향을 받은 파드들을 자동으로 재스케줄링합니다.
3. 초기 장애 발생 약 2분 후, 장애가 발생한 노드가 다시 온라인 상태가 됩니다.

이 과정 전반에 걸쳐 실행 중인 파드의 총 수는 일정하게 유지되어 애플리케이션의 가용성을 보장해야 합니다.

## 클러스터 복구 확인

노드가 다시 온라인 상태가 되기를 기다리는 동안, 클러스터의 자가 치유 능력을 확인하고 필요한 경우 파드를 다시 재생성할 것입니다. 클러스터가 종종 스스로 복구되므로, 현재 상태를 확인하고 가용성 영역(AZ) 전반에 걸쳐 파드가 최적으로 분배되었는지 확인하는 데 중점을 둘 것입니다.

먼저 모든 노드가 `Ready` 상태인지 확인합시다:

```bash timeout=300
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
```

이 명령은 `Ready` 상태인 노드의 총 수를 계산하고 3개의 활성 노드가 모두 준비될 때까지 지속적으로 확인합니다.

모든 노드가 준비되면, 파드들이 노드 전반에 걸쳐 균형있게 분배되도록 재배포할 것입니다:

```bash timeout=900 wait=30
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=dynamodb
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=redis
$ kubectl delete pod --grace-period=0 --force -n assets -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n ui -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=service
$ sleep 90
$ kubectl rollout status -n ui deployment/ui --timeout 180s
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30
```

이 명령들은 다음 작업을 수행합니다:

1. 기존 ui 파드들을 삭제합니다.
2. ui 파드들이 자동으로 프로비저닝될 때까지 기다립니다.
3. `get-pods-by-az.sh` 스크립트를 사용하여 가용성 영역 전반에 걸친 파드 분배를 확인합니다.

## 리테일 스토어 가용성 확인

노드 장애 시뮬레이션 후, 리테일 스토어 애플리케이션이 여전히 접근 가능한지 확인할 수 있습니다. 다음 명령을 사용하여 가용성을 확인하세요:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

이 명령은 인그레스의 로드 밸런서 호스트네임을 가져오고 사용 가능해질 때까지 기다립니다. 준비가 되면, 이 URL을 통해 리테일 스토어에 접속하여 시뮬레이션된 노드 장애에도 불구하고 여전히 제대로 작동하는지 확인할 수 있습니다.

:::caution
리테일 url이 작동하기까지 10분이 걸릴 수 있습니다. 선택적으로 `ctrl` + `z`를 눌러 작업을 백그라운드로 이동시켜 실습을 계속할 수 있습니다. 다시 접근하려면 다음을 입력하세요:

```bash test=false
$ fg %1
```

`wait-for-lb`가 타임아웃될 때까지 url이 작동하지 않을 수 있습니다. 이 경우, 명령을 다시 실행하면 작동하게 될 것입니다:

```bash test=false
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::

## 결론

이 노드 장애 시뮬레이션은 Kubernetes 클러스터의 견고성과 자가 치유 능력을 보여줍니다. 이 실험에서 얻은 주요 관찰사항과 교훈은 다음과 같습니다:

1. Kubernetes가 노드 장애를 신속하게 감지하고 적절히 대응하는 능력
2. 서비스의 연속성을 보장하기 위해 장애 노드에서 정상 노드로 파드를 자동으로 재스케줄링
3. EKS 관리형 노드 그룹을 사용하는 EKS 클러스터의 자가 치유 프로세스가 짧은 시간 후에 장애 노드를 다시 온라인 상태로 복구
4. 노드 장애 시 애플리케이션 가용성을 유지하기 위한 적절한 리소스 할당과 파드 분배의 중요성

이러한 실험을 정기적으로 수행함으로써 다음과 같은 이점을 얻을 수 있습니다:

- 노드 장애에 대한 클러스터의 복원력 검증
- 애플리케이션 아키텍처나 배포 전략의 잠재적 약점 식별
- 예기치 않은 인프라 문제를 처리하는 시스템의 능력에 대한 신뢰 구축
- 인시던트 대응 절차와 자동화 개선