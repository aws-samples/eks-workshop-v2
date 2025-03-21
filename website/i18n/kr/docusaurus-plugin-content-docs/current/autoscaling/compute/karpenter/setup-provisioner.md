---
title: "노드 풀 설정하기"
sidebar_position: 30
---

Karpenter 구성은 `NodePool` CRD(Custom Resource Definition) 형태로 제공됩니다. 하나의 Karpenter `NodePool`은 다양한 파드 형태를 처리할 수 있습니다. Karpenter는 레이블 및 어피니티와 같은 파드 속성을 기반으로 스케줄링 및 프로비저닝 결정을 내립니다. 클러스터에는 여러 개의 `NodePool`이 있을 수 있지만, 지금은 기본 노드 풀 하나를 선언하겠습니다.

Karpenter의 주요 목표 중 하나는 용량 관리를 단순화하는 것입니다. 다른 오토스케일링 솔루션에 익숙하다면, Karpenter가 **그룹 없는 오토스케일링**이라고 하는 다른 접근 방식을 취한다는 것을 알 수 있습니다. 기존의 다른 솔루션들은 전통적으로 **노드 그룹**이라는 개념을 사용하여 제공되는 용량의 특성(예: 온디맨드, EC2 스팟, GPU 노드 등)을 정의하고 클러스터에서 그룹의 원하는 규모를 제어하는 제어 요소로 사용했습니다. AWS에서 노드 그룹의 구현은 [Auto Scaling Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)과 일치합니다. Karpenter를 사용하면 서로 다른 컴퓨팅 요구 사항을 가진 여러 유형의 애플리케이션을 관리하면서 발생하는 복잡성을 피할 수 있습니다.

먼저 Karpenter가 사용하는 몇 가지 사용자 정의 리소스를 적용하겠습니다. 먼저 일반적인 용량 요구 사항을 정의하는 `NodePool`을 생성합니다:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodepool.yaml" paths="spec.template.metadata.labels,spec.template.spec.requirements, spec.limits"}

1. `NodePool`이 모든 새로운 노드를 `type: karpenter` Kubernetes 레이블로 시작하도록 요청하고 있습니다. 이를 통해 데모 목적으로 파드를 Karpenter 노드에 특별히 타겟팅할 수 있습니다.
2. [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/)는 인스턴스 유형과 영역과 같은 노드 속성을 정의할 수 있습니다. 이 예제에서는 `karpenter.sh/capacity-type`을 설정하여 Karpenter가 초기에 온디맨드 인스턴스만 프로비저닝하도록 제한하고, `node.kubernetes.io/instance-type`을 설정하여 특정 인스턴스 유형의 하위 집합으로 제한합니다. [여기에서](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes) 사용 가능한 다른 속성들을 확인할 수 있습니다. 워크샵에서 더 많은 내용을 다룰 예정입니다.
3. `NodePool`은 관리하는 CPU와 메모리의 양에 제한을 정의할 수 있습니다. 이 제한에 도달하면 Karpenter는 해당 `NodePool`과 관련된 추가 용량을 프로비저닝하지 않으며, 총 컴퓨팅 용량에 제한을 둡니다.

그리고 AWS에 적용되는 특정 구성을 제공하는 `EC2NodeClass`도 필요합니다:

::yaml{file="manifests/modules/autoscaling/compute/karpenter/nodepool/nodeclass.yaml" paths="spec.role,spec.subnetSelectorTerms,spec.tags"}

1. Karpenter가 프로비저닝한 EC2 인스턴스에 적용될 IAM 역할을 할당합니다
2. `subnetSelectorTerms`는 Karpenter가 EC2 인스턴스를 시작해야 하는 서브넷을 조회하는 데 사용할 수 있습니다. 이러한 태그는 워크샵에 제공된 관련 AWS 인프라에 자동으로 설정되었습니다. `securityGroupSelectorTerms`는 EC2 인스턴스에 연결될 보안 그룹에 대해 동일한 기능을 수행합니다.
3. EC2 인스턴스에 적용될 태그 세트를 정의하여 회계 및 거버넌스를 가능하게 합니다.

이제 Karpenter가 클러스터의 용량 프로비저닝을 시작하는 데 필요한 기본 요구 사항을 제공했습니다.

다음 명령으로 `NodePool`과 `EC2NodeClass`를 적용하세요:

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/nodepool \
  | envsubst | kubectl apply -f-
```

워크샵 전반에 걸쳐 다음 명령을 사용하여 Karpenter 로그를 검사하고 동작을 이해할 수 있습니다:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | jq '.'
```