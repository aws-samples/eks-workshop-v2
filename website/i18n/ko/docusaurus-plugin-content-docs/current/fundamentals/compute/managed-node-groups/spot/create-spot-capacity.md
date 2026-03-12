---
title: "Spot 용량 생성"
sidebar_position: 20
tmdTranslationSourceHash: 'ddb385af0a0fff6e267d4c4f1b54846b'
---

Spot 인스턴스를 생성하는 관리형 노드 그룹을 배포한 다음, 새로 생성된 Spot 인스턴스에서 실행되도록 애플리케이션의 기존 `catalog` 컴포넌트를 수정하겠습니다.

먼저 기존 EKS 클러스터의 모든 노드를 나열하는 것으로 시작할 수 있습니다. `kubectl get nodes` 명령을 사용하여 Kubernetes 클러스터의 노드를 나열할 수 있지만, 용량 타입에 대한 추가 세부 정보를 얻기 위해 `-L eks.amazonaws.com/capacityType` 파라미터를 사용하겠습니다.

다음 명령은 현재 노드가 **온디맨드** 인스턴스임을 보여줍니다.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType
NAME                                          STATUS   ROLES    AGE    VERSION                CAPACITYTYPE
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
```

:::tip
`온디맨드` 인스턴스와 같이 특정 용량 타입을 기반으로 노드를 검색하려면 "<b>레이블 셀렉터</b>"를 활용할 수 있습니다. 이 특정 시나리오에서는 레이블 셀렉터를 `capacityType=ON_DEMAND`로 설정하여 이를 달성할 수 있습니다.

```bash
$ kubectl get nodes -l eks.amazonaws.com/capacityType=ON_DEMAND

NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-119.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-200.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-94.us-east-2.compute.internal    Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-235.us-east-2.compute.internal   Ready    <none>   4h34m   vVAR::KUBERNETES_NODE_VERSION
```

:::

아래 다이어그램에는 클러스터 내의 관리형 노드 그룹을 나타내는 두 개의 별도 "노드 그룹"이 있습니다. 첫 번째 Node Group 박스는 On-Demand 인스턴스를 포함하는 노드 그룹을 나타내고, 두 번째는 Spot 인스턴스를 포함하는 노드 그룹을 나타냅니다. 둘 다 지정된 EKS 클러스터와 연결되어 있습니다.

![spot arch](/docs/fundamentals/compute/managed-node-groups/spot/managed-spot-arch.webp)

Spot 인스턴스로 노드 그룹을 생성해 보겠습니다. 다음 명령은 새로운 노드 그룹 `managed-spot`을 생성합니다.

```bash wait=10
$ aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot \
  --node-role $SPOT_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types c5.large c5d.large c5a.large c5ad.large c6a.large \
  --capacity-type SPOT \
  --scaling-config minSize=2,maxSize=3,desiredSize=2 \
  --disk-size 20
```

`--capacity-type SPOT` 인자는 이 관리형 노드 그룹의 모든 용량이 Spot이어야 함을 나타냅니다.

:::tip
`aws eks wait nodegroup-active` 명령을 사용하여 특정 EKS 노드 그룹이 활성화되고 사용 준비가 될 때까지 기다릴 수 있습니다. 이 명령은 AWS CLI의 일부이며, 지정된 노드 그룹이 성공적으로 생성되고 모든 관련 인스턴스가 실행 중이며 준비 상태인지 확인하는 데 사용할 수 있습니다.

```bash wait=30 timeout=300
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot
```

:::

새로운 관리형 노드 그룹이 **Active** 상태가 되면 다음 명령을 실행합니다.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup

NAME                                          STATUS   ROLES    AGE     VERSION                CAPACITYTYPE   NODEGROUP
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-178-46.us-east-2.compute.internal    Ready    <none>   103s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
ip-10-42-97-19.us-east-2.compute.internal     Ready    <none>   104s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
```

출력 결과는 노드 그룹 `managed-spot` 아래에 용량 타입이 `SPOT`인 두 개의 추가 노드가 프로비저닝되었음을 보여줍니다.

