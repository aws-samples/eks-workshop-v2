---
title: "FIS를 사용한 부분적 노드 장애 시뮬레이션"
sidebar_position: 150
description: "AWS Fault Injection Simulator를 사용하여 Kubernetes 환경에서 부분적 노드 장애를 시뮬레이션하여 애플리케이션 복원력을 테스트합니다."
---

## AWS Fault Injection Simulator (FIS) 개요

AWS Fault Injection Simulator (FIS)는 AWS 워크로드에서 제어된 장애 주입 실험을 수행할 수 있게 해주는 완전 관리형 서비스입니다. FIS를 통해 다양한 장애 시나리오를 시뮬레이션할 수 있으며, 이는 다음과 같은 목적으로 중요합니다:

1. 고가용성 구성 검증
2. 자동 확장 및 자가 복구 기능 테스트
3. 잠재적인 단일 장애 지점 식별
4. 인시던트 대응 절차 개선

FIS를 사용하면 다음과 같은 작업을 수행할 수 있습니다:

- 숨겨진 버그와 성능 병목 현상 발견
- 스트레스 상황에서 시스템의 동작 방식 관찰
- 자동화된 복구 절차 구현 및 검증
- 일관된 동작을 보장하기 위한 반복 가능한 실험 수행

우리의 FIS 실험에서는 EKS 클러스터에서 부분적 노드 장애를 시뮬레이션하고 애플리케이션의 반응을 관찰하여 복원력 있는 시스템 구축에 대한 실질적인 통찰력을 제공할 것입니다.

:::info
AWS FIS에 대한 자세한 정보는 다음을 참조하세요:

- [AWS Fault Injection Service란 무엇입니까?](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html)
- [AWS Fault Injection Simulator 콘솔](https://console.aws.amazon.com/fis/home)
- [AWS Systems Manager, Automation](https://console.aws.amazon.com/systems-manager/automation/executions)

:::

## 실험 세부 사항

이 실험은 이전의 수동 노드 장애 시뮬레이션과 다음과 같은 여러 가지 면에서 다릅니다:

1. **자동화된 실행**: FIS가 실험을 관리하여 이전 실험의 수동 스크립트 실행에 비해 더 제어되고 반복 가능한 테스트가 가능합니다.
2. **부분 장애**: 단일 노드의 완전한 장애를 시뮬레이션하는 대신, FIS를 사용하면 여러 노드에 걸쳐 부분적 장애를 시뮬레이션할 수 있습니다. 이는 더 미묘하고 현실적인 장애 시나리오를 제공합니다.
3. **규모**: FIS를 사용하면 여러 노드를 동시에 대상으로 지정할 수 있습니다. 이를 통해 수동 실험의 단일 노드 장애에 비해 더 큰 규모에서 애플리케이션의 복원력을 테스트할 수 있습니다.
4. **정밀도**: 종료할 인스턴스의 정확한 비율을 지정할 수 있어 실험에 대한 세밀한 제어가 가능합니다. 전체 노드 종료로 제한되었던 수동 실험에서는 이러한 수준의 제어가 불가능했습니다.
5. **최소한의 중단**: FIS 실험은 테스트 전반에 걸쳐 서비스 가용성을 유지하도록 설계되었으며, 수동 노드 장애는 리테일 스토어의 접근성에 일시적인 중단을 초래했을 수 있습니다.

이러한 차이점들은 실험 매개변수에 대한 더 나은 제어를 유지하면서 애플리케이션의 장애 복원력에 대한 더 포괄적이고 현실적인 테스트를 가능하게 합니다. 이 실험에서 FIS는 두 노드 그룹에서 66%의 인스턴스를 종료하여 클러스터의 상당한 부분 장애를 시뮬레이션합니다. 이전 실험과 마찬가지로 이 실험도 반복 가능합니다.

## 노드 장애 실험 생성

부분적 노드 장애를 시뮬레이션하기 위한 새로운 AWS FIS 실험 템플릿을 생성합니다:

```bash wait=30
$ export NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"COUNT(2)"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"66"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## 실험 실행

FIS 실험을 실행하여 노드 장애를 시뮬레이션하고 응답을 모니터링합니다:

```bash timeout=300
$ aws fis start-experiment --experiment-template-id $NODE_EXP_ID --output json && timeout --preserve-status 240s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-s6kw4   1/1   Running   0     2m16s
       ui-6dfb84cf67-vwk4x   1/1   Running   0     4m54s

------us-west-2b------

------us-west-2c------
  ip-10-42-180-16.us-west-2.compute.internal:
       ui-6dfb84cf67-29xtf   1/1   Running   0     79s
       ui-6dfb84cf67-68hbw   1/1   Running   0     79s
       ui-6dfb84cf67-plv9f   1/1   Running   0     79s

```

이 명령은 노드 장애를 트리거하고 4분 동안 파드를 모니터링하여 클러스터가 용량의 상당 부분을 잃었을 때 어떻게 반응하는지 관찰할 수 있게 합니다.

실험 중에 다음과 같은 현상이 관찰되어야 합니다:

1. 약 1분 후, 하나 이상의 노드가 목록에서 사라지는 것을 볼 수 있으며, 이는 시뮬레이션된 부분 노드 장애를 나타냅니다.
2. 다음 2분 동안, 파드들이 남아있는 정상 노드들로 재스케줄링되고 재분배되는 것을 볼 수 있습니다.
3. 곧이어 종료된 노드를 대체하기 위한 새로운 노드가 온라인 상태가 되는 것을 볼 수 있습니다.

FIS를 사용하지 않은 노드 장애와 달리 리테일 URL은 계속 작동해야 합니다.

:::note
노드를 확인하고 파드를 재조정하려면 다음을 실행하세요:

```bash timeout=900 wait=30
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
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

:::

## 리테일 스토어 가용성 확인

부분적 노드 장애 동안 리테일 스토어 애플리케이션이 계속 작동하는지 확인하세요. 다음 명령을 사용하여 가용성을 확인하세요:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

:::tip
리테일 URL이 작동하기까지 10분이 걸릴 수 있습니다.
:::

부분적 노드 장애에도 불구하고 리테일 스토어는 계속해서 트래픽을 처리해야 하며, 이는 배포 설정의 복원력을 보여줍니다.

## 결론

AWS FIS를 사용한 이 부분적 노드 장애 시뮬레이션은 Kubernetes 클러스터의 복원력에 대한 여러 핵심 측면을 보여줍니다:

1. Kubernetes의 자동 노드 장애 감지
2. 장애 노드에서 정상 노드로의 신속한 파드 재스케줄링
3. 상당한 인프라 중단 중에도 서비스 가용성을 유지하는 클러스터의 능력
4. 장애 노드를 대체하는 자동 확장 기능

이 실험의 주요 교훈:

- 여러 노드와 가용 영역에 걸쳐 워크로드를 분산하는 것의 중요성
- 파드에 대한 적절한 리소스 요청과 제한 설정의 가치
- Kubernetes 자가 복구 메커니즘의 효과
- 노드 장애를 감지하고 대응하기 위한 강력한 모니터링 및 경고 시스템의 필요성

이러한 실험을 위해 AWS FIS를 활용함으로써 얻을 수 있는 여러 이점:

1. **반복 가능성**: 일관된 동작을 보장하기 위해 이 실험을 여러 번 실행할 수 있습니다.
2. **자동화**: FIS를 통해 정기적인 복원력 테스트를 예약할 수 있어, 시스템이 시간이 지나도 장애 허용 능력을 유지하도록 보장합니다.
3. **포괄적인 테스트**: 전체 애플리케이션 스택을 테스트하기 위해 여러 AWS 서비스가 관련된 더 복잡한 시나리오를 만들 수 있습니다.
4. **제어된 혼돈**: FIS는 프로덕션 시스템에 의도하지 않은 손상을 줄 위험 없이 카오스 엔지니어링 실험을 수행할 수 있는 안전하고 관리된 환경을 제공합니다.

이러한 실험을 정기적으로 실행하면 시스템의 복원력에 대한 신뢰를 구축하고 아키텍처와 운영 절차를 지속적으로 개선하기 위한 귀중한 통찰력을 제공합니다.