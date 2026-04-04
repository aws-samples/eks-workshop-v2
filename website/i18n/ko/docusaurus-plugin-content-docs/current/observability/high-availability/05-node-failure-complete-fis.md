---
title: "FIS로 완전한 노드 장애 시뮬레이션"
sidebar_position: 170
description: "AWS Fault Injection Simulator를 사용하여 Kubernetes 환경에서 완전한 노드 장애의 영향을 시연합니다."
tmdTranslationSourceHash: '54b49f6f0bbfaaaf81aaea50ea19b29e'
---

## 개요

이 실험은 이전의 부분적 노드 장애 테스트를 확장하여 EKS 클러스터의 모든 노드가 완전히 장애가 발생하는 상황을 시뮬레이션합니다. 이는 본질적으로 클러스터 장애입니다. AWS Fault Injection Simulator (FIS)를 사용하여 극단적인 시나리오를 테스트하고 재앙적인 상황에서 시스템의 탄력성을 검증하는 방법을 보여줍니다.

## 실험 세부 사항

이 실험은 부분적 노드 장애와 유사하게 반복 가능합니다. 부분적 노드 장애 시뮬레이션과 달리 이 실험은:

1. 모든 노드 그룹의 인스턴스를 100% 종료합니다.
2. 클러스터가 완전한 장애 상태에서 복구하는 능력을 테스트합니다.
3. 완전한 중단에서 전체 복원까지 전체 복구 프로세스를 관찰할 수 있습니다.

## 노드 장애 실험 생성

완전한 노드 장애를 시뮬레이션하기 위한 새로운 AWS FIS 실험 템플릿을 생성합니다:

```bash wait=30
$ export FULL_NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"ALL"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"100"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## 실험 실행

FIS 실험을 실행하고 클러스터의 응답을 모니터링합니다:

```bash timeout=420
$ aws fis start-experiment --experiment-template-id $FULL_NODE_EXP_ID --output json && timeout --preserve-status 360s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-106-250.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2b------
  ip-10-42-141-133.us-west-2.compute.internal:
       ui-6dfb84cf67-n9xns   1/1   Running   0     4m8s
       ui-6dfb84cf67-slknv   1/1   Running   0     2m48s

------us-west-2c------
  ip-10-42-179-59.us-west-2.compute.internal:
       ui-6dfb84cf67-5xht5   1/1   Running   0     4m52s
       ui-6dfb84cf67-b6xbf   1/1   Running   0     4m10s
       ui-6dfb84cf67-fpg8j   1/1   Running   0     4m52s
```

이 명령은 실험을 관찰하는 동안 6분 동안 Pod 배포를 표시합니다. 다음을 확인할 수 있습니다:

1. 실험이 시작된 직후, 모든 노드와 Pod가 사라집니다.
2. 약 2분 후, 첫 번째 노드와 일부 Pod가 다시 온라인 상태가 됩니다.
3. 약 4분 경과 시, 두 번째 노드가 나타나고 더 많은 Pod가 시작됩니다.
4. 6분 경과 시, 마지막 노드가 온라인 상태가 되면서 지속적인 복구가 진행됩니다.

실험의 심각성으로 인해 테스트 중에는 retail store url이 작동하지 않습니다. 마지막 노드가 작동한 후 url이 다시 작동해야 합니다. 이 테스트 후에도 노드가 작동하지 않으면 계속 진행하기 전에 `~/$SCRIPT_DIR/verify-clsuter.sh`를 실행하여 마지막 노드가 실행 중 상태로 변경될 때까지 기다립니다.

:::note
노드와 Pod 재배포를 확인하려면 다음을 실행할 수 있습니다:

```bash timeout=900 wait=30
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=dynamodb
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=redis
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n ui -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=service
$ sleep 90
$ kubectl rollout status -n ui deployment/ui --timeout 180s
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30
```

:::

## 실험 후 검증

실험 후 시뮬레이션된 AZ 장애에도 불구하고 애플리케이션이 작동 상태로 유지되는지 확인합니다:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

:::tip
retail url이 작동하는 데 10분이 걸릴 수 있습니다.
:::

## 결론

이 실험은 다음을 보여줍니다:

1. 재앙적인 장애에 대한 클러스터의 응답.
2. 모든 실패한 노드를 교체하는 오토스케일링의 효과.
3. 모든 Pod를 새 노드에 재스케줄링하는 Kubernetes의 능력.
4. 완전한 장애로부터 전체 시스템 복구 시간.

주요 학습 내용:

- 강력한 오토스케일링 구성의 중요성.
- 효과적인 Pod 우선순위 및 선점 설정의 가치.
- 완전한 클러스터 장애를 견딜 수 있는 아키텍처의 필요성.
- 극단적인 시나리오에 대한 정기적인 테스트의 중요성.

FIS를 사용하여 이러한 테스트를 수행함으로써 재앙적인 장애를 안전하게 시뮬레이션하고, 복구 절차를 검증하고, 중요한 종속성을 식별하며, 복구 시간을 측정할 수 있습니다. 이는 재해 복구 계획을 개선하고 전반적인 시스템 탄력성을 향상시키는 데 도움이 됩니다.

