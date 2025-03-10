---
title: 스팟 용량 생성
sidebar_position: 20
---


온디맨드 인스턴스 대신 스팟 인스턴스를 생성하는 관리형 노드 그룹을 배포한 다음, 새로 생성된 스팟 인스턴스에서 실행되도록 애플리케이션의 기존 `catalog` 컴포넌트를 수정해 보겠습니다.

먼저 기존 EKS 클러스터의 모든 노드를 나열해 보겠습니다. `kubectl get nodes` 명령을 사용하여 Kubernetes 클러스터의 노드를 나열할 수 있지만, 용량 유형에 대한 추가 세부 정보를 얻기 위해 `-L eks.amazonaws.com/capacityType` 매개변수를 사용하겠습니다.

다음 명령은 현재 우리의 노드가 **온디맨드** 인스턴스임을 보여줍니다.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType
NAME                                          STATUS   ROLES    AGE    VERSION                CAPACITYTYPE
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   133m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND
```

:::tip
`on-demand` 인스턴스와 같은 특정 용량 유형에 기반한 노드를 검색하려면 **레이블 선택기**를 활용할 수 있습니다. 이 특정 시나리오에서는 레이블 선택기를 `capacityType=ON_DEMAND`로 설정하여 이를 달성할 수 있습니다.

```bash
$ kubectl get nodes -l eks.amazonaws.com/capacityType=ON_DEMAND

NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-119.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-200.us-east-2.compute.internal   Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-94.us-east-2.compute.internal    Ready    <none>   3d10h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-235.us-east-2.compute.internal   Ready    <none>   4h34m   vVAR::KUBERNETES_NODE_VERSION
```

:::

아래 다이어그램에는 클러스터 내의 관리형 노드 그룹을 나타내는 두 개의 별도 "노드 그룹"이 있습니다. 첫 번째 노드 그룹 상자는 온디맨드 인스턴스를 포함하는 노드 그룹을 나타내고, 두 번째는 스팟 인스턴스를 포함하는 노드 그룹을 나타냅니다. 둘 다 지정된 EKS 클러스터와 연결되어 있습니다.

![spot arch](./assets/managed-spot-arch.webp)

이제 스팟 인스턴스로 노드 그룹을 생성해 보겠습니다. 다음 명령은 새로운 노드 그룹 `managed-spot`을 생성합니다.

```bash
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

`--capacity-type SPOT` 인수는 이 관리형 노드 그룹의 모든 용량이 스팟이어야 함을 나타냅니다.

The `--capacity-type SPOT` argument indicates that all capacity in this managed node group should be Spot.

:::tip
`aws eks wait nodegroup-active` 명령을 사용하여 특정 EKS 노드 그룹이 활성화되고 사용 준비가 될 때까지 기다릴 수 있습니다. 이 명령은 AWS CLI의 일부이며, 지정된 노드 그룹이 성공적으로 생성되고 모든 관련 인스턴스가 실행되어 준비되었는지 확인하는 데 사용할 수 있습니다.

```bash
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot
```

:::

새로운 관리형 노드 그룹이 **Active** 상태가 되면 다음 명령을 실행하세요.

```bash
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup

NAME                                          STATUS   ROLES    AGE     VERSION                CAPACITYTYPE   NODEGROUP
ip-10-42-103-103.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-142-197.us-east-2.compute.internal   Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-161-44.us-east-2.compute.internal    Ready    <none>   3h38m   vVAR::KUBERNETES_NODE_VERSION      ON_DEMAND      default
ip-10-42-178-46.us-east-2.compute.internal    Ready    <none>   103s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
ip-10-42-97-19.us-east-2.compute.internal     Ready    <none>   104s    vVAR::KUBERNETES_NODE_VERSION      SPOT           managed-spot
```

출력은 `managed-spot` 노드 그룹 아래에 용량 유형이 `SPOT`인 두 개의 추가 노드가 프로비저닝되었음을 보여줍니다.
