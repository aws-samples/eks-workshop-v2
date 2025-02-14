---
title: "자동 노드 프로비저닝"
sidebar_position: 40
---
스케줄링할 수 없는 파드의 요구사항에 따라 Karpenter가 어떻게 적절한 크기의 EC2 인스턴스를 동적으로 프로비저닝하는지 살펴보면서 Karpenter 작업을 시작해보겠습니다. 이를 통해 EKS 클러스터의 미사용 컴퓨팅 리소스를 줄일 수 있습니다.

이전 섹션에서 생성한 NodePool은 Karpenter가 사용할 수 있는 특정 인스턴스 유형을 지정했습니다. 이러한 인스턴스 유형을 살펴보겠습니다:


| 인스턴스 유형 | vCPU | 메모리 | 가격 |
| ------------- | ---- | ------ | ---- |
| `c5.large`    | 2    | 4GB    | +    |
| `m5.large`    | 2    | 8GB    | ++   |
| `r5.large`    | 2    | 16GB   | +++  |
| `m5.xlarge`   | 4    | 16GB   | ++++ |

파드를 몇 개 생성하고 Karpenter가 어떻게 적응하는지 살펴보겠습니다. 현재 Karpenter가 관리하는 노드는 없습니다:

```bash
$ kubectl get node -l type=karpenter
No resources found
```

다음 Deployment를 사용하여 Karpenter의 스케일 아웃을 트리거하겠습니다:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/scale/deployment.yaml" paths="spec.replicas,spec.template.spec.nodeSelector,spec.template.spec.containers.0.image,spec.template.spec.containers.0.resources"}

1. 초기에는 실행할 레플리카를 0개로 지정하고, 나중에 스케일 업할 예정입니다
2. NodePool과 일치하는 노드 셀렉터를 사용하여 Karpenter가 프로비저닝한 용량에 파드가 스케줄링되도록 요구합니다
3. 간단한 `pause` 컨테이너 이미지를 사용합니다
4. 각 파드에 대해 `1Gi`의 메모리를 요청합니다

:::info `pause` 컨테이너란 무엇인가요?
이 예제에서 다음 이미지를 사용하고 있음을 알 수 있습니다:

`public.ecr.aws/eks-distro/kubernetes/pause`

이는 실제 리소스를 거의 사용하지 않고 빠르게 시작되는 작은 컨테이너로, 스케일링 시나리오를 보여주는 데 매우 적합합니다. 이 특정 실습에서 많은 예제에 이것을 사용할 것입니다.
:::

이 deployment를 적용하세요:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/scale
deployment.apps/inflate created
```

이제 Karpenter가 최적화된 결정을 내리는 것을 보여주기 위해 의도적으로 이 deployment를 스케일링해보겠습니다. `1Gi`의 메모리를 요청했으므로, deployment를 5개의 레플리카로 스케일링하면 총 5Gi의 메모리가 요청됩니다.

계속 진행하기 전에, 위 표에서 Karpenter가 어떤 인스턴스를 프로비저닝할 것 같나요? 어떤 인스턴스 유형을 원하시나요?

deployment를 스케일링하세요:

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

이 작업은 하나 이상의 새로운 EC2 인스턴스를 생성하므로 시간이 걸립니다. 다음 명령으로 `kubectl`을 사용하여 완료될 때까지 기다릴 수 있습니다:

```bash
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

모든 파드가 실행되면 어떤 인스턴스 유형이 선택되었는지 확인해보겠습니다:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'launched nodeclaim' | jq '.'
```

인스턴스 유형과 구매 옵션을 나타내는 출력이 표시되어야 합니다:

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:32:00.413Z",
  "logger": "controller.nodeclaim.lifecycle",
  "message": "launched nodeclaim",
  "commit": "1072d3b",
  "nodeclaim": "default-xxm79",
  "nodepool": "default",
  "provider-id": "aws:///us-west-2a/i-0bb8a7e6111d45591",
  # HIGHLIGHT
  "instance-type": "m5.large",
  "zone": "us-west-2a",
  # HIGHLIGHT
  "capacity-type": "on-demand",
  "allocatable": {
    "cpu": "1930m",
    "ephemeral-storage": "17Gi",
    "memory": "6903Mi",
    "pods": "29",
    "vpc.amazonaws.com/pod-eni": "9"
  }
}
```

스케줄링한 파드들은 8GB 메모리를 가진 EC2 인스턴스에 잘 맞을 것이며, Karpenter는 온디맨드 인스턴스의 경우 항상 가장 낮은 가격의 인스턴스 유형을 우선시하므로 `m5.large`를 선택할 것입니다.

:::info
작업 중인 리전에서 가장 저렴한 인스턴스 유형의 용량이 남아있지 않은 경우와 같이, 가장 저렴한 것이 아닌 다른 인스턴스 유형이 선택되는 특정 경우가 있습니다
:::

Karpenter가 노드에 추가한 메타데이터도 확인할 수 있습니다:

```bash
$ kubectl get node -l type=karpenter -o jsonpath='{.items[0].metadata.labels}' | jq '.'
```

이 출력은 인스턴스 유형, 구매 옵션, 가용 영역 등과 같은 설정된 다양한 레이블을 보여줍니다:

```json
{
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "1911afb91fc78905500a801c7b5ae731",
  "karpenter.k8s.aws/instance-category": "m",
  "karpenter.k8s.aws/instance-cpu": "2",
  "karpenter.k8s.aws/instance-family": "m5",
  "karpenter.k8s.aws/instance-generation": "5",
  "karpenter.k8s.aws/instance-hypervisor": "nitro",
  "karpenter.k8s.aws/instance-memory": "8192",
  "karpenter.k8s.aws/instance-pods": "29",
  "karpenter.k8s.aws/instance-size": "large",
  "karpenter.sh/capacity-type": "on-demand",
  "karpenter.sh/initialized": "true",
  "karpenter.sh/provisioner-name": "default",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-100-64-10-200.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.ebs.csi.aws.com/zone": "us-west-2a",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "type": "karpenter",
  "vpc.amazonaws.com/has-trunk-attached": "true"
}
```

이 간단한 예제는 Karpenter가 컴퓨팅 용량이 필요한 워크로드의 리소스 요구사항에 따라 적절한 인스턴스 유형을 동적으로 선택할 수 있다는 것을 보여줍니다. 이는 단일 노드 그룹 내의 인스턴스 유형이 일관된 CPU와 메모리 특성을 가져야 하는 Cluster Autoscaler와 같은 노드 풀 중심 모델과는 근본적으로 다릅니다.
