---
title: Graviton 노드 생성
sidebar_position: 10
tmdTranslationSourceHash: '796beaca8412816af0badbdbcfedf8b1'
---

이번 실습에서는 Graviton 기반 인스턴스를 사용하는 별도의 관리형 노드 그룹을 프로비저닝하고 여기에 taint를 적용하겠습니다.

먼저 클러스터에서 사용 가능한 노드의 현재 상태를 확인해 보겠습니다:

```bash
$ kubectl get nodes -L kubernetes.io/arch
NAME                                           STATUS   ROLES    AGE     VERSION                ARCH
ip-192-168-102-2.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-137-20.us-west-2.compute.internal   Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-19-31.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
```

출력 결과는 각 노드의 CPU 아키텍처를 표시하는 열과 함께 기존 노드를 보여줍니다. 현재 이들은 모두 `amd64` 노드를 사용하고 있습니다.

:::note
아직 taint를 구성하지 않으며, 이는 나중에 수행됩니다.
:::

다음 명령은 Graviton 노드 그룹을 생성합니다:

```bash timeout=600 hook=configure-taints
$ aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  --node-role $GRAVITON_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types t4g.medium \
  --ami-type AL2023_ARM_64_STANDARD \
  --scaling-config minSize=1,maxSize=3,desiredSize=1 \
  --disk-size 20
```

:::tip
`aws eks wait nodegroup-active` 명령을 사용하여 특정 EKS 노드 그룹이 활성화되어 사용 준비가 될 때까지 기다릴 수 있습니다. 이 명령은 AWS CLI의 일부이며 지정된 노드 그룹이 성공적으로 생성되고 관련된 모든 인스턴스가 실행되어 준비 상태가 되었는지 확인하는 데 사용할 수 있습니다.

```bash wait=30 timeout=300
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

:::

새 관리형 노드 그룹이 **Active** 상태가 되면 다음 명령을 실행합니다:

```bash
$ kubectl get nodes \
    --label-columns eks.amazonaws.com/nodegroup,kubernetes.io/arch

NAME                                          STATUS   ROLES    AGE    VERSION               NODEGROUP   ARCH
ip-192-168-102-2.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-137-20.us-west-2.compute.internal  Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-19-31.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-10-42-172-231.us-west-2.compute.internal   Ready    <none>   2m5s   vVAR::KUBERNETES_NODE_VERSION     graviton    arm64
```

아래 명령은 `--selector` 플래그를 사용하여 관리형 노드 그룹 `graviton`의 이름과 일치하는 `eks.amazonaws.com/nodegroup` 레이블을 가진 모든 노드를 쿼리합니다. `--label-columns` 플래그를 사용하면 출력에서 `eks.amazonaws.com/nodegroup` 레이블의 값과 프로세서 아키텍처를 표시할 수 있습니다. `ARCH` 열은 Graviton `arm64` 프로세서를 실행하는 taint가 적용된 노드 그룹을 보여줍니다.

노드의 현재 구성을 살펴보겠습니다. 다음 명령은 관리형 노드 그룹에 속한 모든 노드의 세부 정보를 나열합니다.

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton
Name:               ip-10-42-12-233.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-0b55230f107a87100
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-07afc97c4940b6622
                    kubernetes.io/arch=arm64
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             <none>
[...]
```

주목할 몇 가지 사항:

1. EKS는 OS 유형, 관리형 노드 그룹 이름, 인스턴스 유형 등을 포함하여 더 쉽게 필터링할 수 있도록 특정 레이블을 자동으로 추가합니다. EKS에서 기본적으로 제공되는 특정 레이블이 있지만, AWS는 운영자가 관리형 노드 그룹 수준에서 자체 커스텀 레이블 세트를 구성할 수 있도록 허용합니다. 이를 통해 노드 그룹 내의 모든 노드가 일관된 레이블을 갖도록 보장합니다. `kubernetes.io/arch` 레이블은 ARM64 CPU 아키텍처를 가진 EC2 인스턴스를 실행하고 있음을 보여줍니다.
2. 현재 탐색된 노드에는 구성된 taint가 없으며, 이는 `Taints: <none>` 항목으로 표시됩니다.

## 관리형 노드 그룹에 대한 Taint 구성

[여기](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts)에 설명된 대로 `kubectl` CLI를 사용하여 노드에 taint를 적용하는 것은 쉽지만, 관리자는 기본 노드 그룹이 스케일 업 또는 다운될 때마다 이 변경을 수행해야 합니다. 이러한 문제를 극복하기 위해 AWS는 관리형 노드 그룹에 `labels`와 `taints`를 모두 추가할 수 있도록 지원하여 MNG 내의 모든 노드가 관련 레이블과 taint를 자동으로 구성하도록 보장합니다.

이제 사전 구성된 관리형 노드 그룹 `graviton`에 taint를 추가하겠습니다. 이 taint는 `key=frontend`, `value=true`, `effect=NO_EXECUTE`를 가집니다. 이는 taint가 적용된 관리형 노드 그룹에서 이미 실행 중인 Pod가 일치하는 toleration이 없는 경우 제거되도록 보장합니다. 또한 적절한 toleration이 없으면 새로운 Pod가 이 관리형 노드 그룹에 스케줄링되지 않습니다.

다음 `aws` cli 명령을 사용하여 관리형 노드 그룹에 `taint`를 추가하는 것부터 시작하겠습니다:

```bash wait=20
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME --nodegroup-name graviton \
    --taints "addOrUpdateTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
{
    "update": {
        "id": "488a2b7d-9194-3032-974e-2f1056ef9a1b",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "TaintsToAdd",
                "value": "[{\"effect\":\"NO_EXECUTE\",\"value\":\"true\",\"key\":\"frontend\"}]"
            }
        ],
        "createdAt": "2022-11-09T15:20:10.519000+00:00",
        "errors": []
    }
}
```

다음 명령을 실행하여 노드 그룹이 활성 상태가 될 때까지 기다립니다.

```bash timeout=180
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

Taint의 추가, 제거 또는 교체는 [`aws eks update-nodegroup-config`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) CLI 명령을 사용하여 관리형 노드 그룹의 구성을 업데이트함으로써 수행할 수 있습니다. 이는 `addOrUpdateTaints` 또는 `removeTaints`와 taint 목록을 `--taints` 명령 플래그에 전달하여 수행할 수 있습니다.

:::tip
`eksctl` CLI를 사용하여 관리형 노드 그룹에 taint를 구성할 수도 있습니다. 자세한 내용은 [문서](https://eksctl.io/usage/nodegroup-taints/)를 참조하세요.
:::

taint 구성에서 `effect=NO_EXECUTE`를 사용했습니다. 관리형 노드 그룹은 현재 taint `effect`에 대해 다음 값을 지원합니다:

- `NO_SCHEDULE` - Kubernetes `NoSchedule` taint 효과에 해당합니다. 일치하는 toleration이 없는 모든 Pod를 거부하는 taint로 관리형 노드 그룹을 구성합니다. 실행 중인 모든 Pod는 관리형 노드 그룹의 노드에서 **제거되지 않습니다**.
- `NO_EXECUTE` - Kubernetes `NoExecute` taint 효과에 해당합니다. 이 taint로 구성된 노드가 새로 스케줄링된 Pod를 거부할 뿐만 아니라 일치하는 toleration이 없는 실행 중인 Pod도 **제거**할 수 있도록 합니다.
- `PREFER_NO_SCHEDULE` - Kubernetes `PreferNoSchedule` taint 효과에 해당합니다. 가능하면 EKS는 이 taint를 용인하지 않는 Pod를 노드에 스케줄링하지 않습니다.

다음 명령을 사용하여 관리형 노드 그룹에 대해 taint가 올바르게 구성되었는지 확인할 수 있습니다:

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  | jq .nodegroup.taints
[
  {
    "key": "frontend",
    "value": "true",
    "effect": "NO_EXECUTE"
  }
]
```

:::info

관리형 노드 그룹을 업데이트하고 레이블과 taint를 전파하는 데는 보통 몇 분이 걸립니다. 구성된 taint가 표시되지 않거나 `null` 값을 받는 경우 위 명령을 다시 시도하기 전에 몇 분 정도 기다려 주세요.

:::

`kubectl` cli 명령으로 확인하면 taint가 관련 노드에 올바르게 전파된 것을 확인할 수 있습니다:

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton | grep Taints
Taints:             frontend=true:NoExecute
```

