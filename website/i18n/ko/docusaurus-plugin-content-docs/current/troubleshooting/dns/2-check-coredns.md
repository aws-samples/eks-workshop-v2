---
title: "CoreDNS Pod 확인"
sidebar_position: 52
tmdTranslationSourceHash: '49b317983e950e56300ddbf081a229fa'
---

EKS 클러스터에서 CoreDNS Pod가 DNS 확인을 처리합니다. 이러한 Pod가 올바르게 실행되고 있는지 확인해 보겠습니다.

### 1단계 - Pod 상태 확인

먼저, kube-system 네임스페이스에서 CoreDNS Pod를 확인합니다:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-6fdb8f5699-dq7xw   0/1     Pending   0          42s
CoreDNS-6fdb8f5699-z57jw   0/1     Pending   0          42s
```

CoreDNS Pod가 실행되고 있지 않은 것을 볼 수 있으며, 이는 클러스터의 DNS 확인 문제를 명확히 설명합니다.

:::info
Pod가 Pending 상태에 있으며, 이는 어떤 노드에도 스케줄링되지 않았음을 나타냅니다.
:::

### 2단계 - Pod 이벤트 확인

Pod 설명에서 이러한 Pod와 관련된 이벤트를 확인하여 더 자세히 조사해 보겠습니다:

```bash timeout=30
$ kubectl describe po -l k8s-app=kube-dns -n kube-system | sed -n '/Events:/,/^$/p'

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

경고 메시지는 노드 레이블과 CoreDNS Pod의 node selector/affinity 간의 불일치를 나타냅니다.

### 3단계 - 노드 선택 확인

CoreDNS Pod의 node selector를 살펴보겠습니다:

```bash timeout=30
$ kubectl get deployment coredns -n kube-system -o jsonpath='{.spec.template.spec.nodeSelector}' | jq
{
  "workshop-default": "no"
}
```

이제 워커 노드의 레이블을 확인합니다:

```bash timeout=30
$ kubectl get node -o jsonpath='{.items[0].metadata.labels}' | jq
{
  "alpha.eksctl.io/cluster-name": "eks-workshop",
  "alpha.eksctl.io/nodegroup-name": "default",
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "eks.amazonaws.com/capacityType": "ON_DEMAND",
  "eks.amazonaws.com/nodegroup": "default",
  "eks.amazonaws.com/nodegroup-image": "ami-07fdc65a0c344a252",
  "eks.amazonaws.com/sourceLaunchTemplateId": "lt-0f7c7c3c9cb770aaa",
  "eks.amazonaws.com/sourceLaunchTemplateVersion": "1",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "b2c4991f4c3acb5b142be2a5d455731a",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-10-42-100-65.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.k8s.aws/zone-id": "usw2-az1",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "workshop-default": "yes"
}
```

CoreDNS Pod는 `workshop-default: no` 레이블이 있는 노드가 필요하지만, 노드는 `workshop-default: yes`로 레이블이 지정되어 있습니다.

:::info
Pod의 yaml 매니페스트에는 노드에서 Pod 스케줄링에 영향을 주는 다양한 옵션이 있습니다. 다른 파라미터로는 affinity, anti-affinity 및 Pod Topology Spread Constraints가 있습니다. 자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)를 참조하세요.
:::

### 근본 원인

프로덕션 환경에서 팀은 종종 클러스터 시스템 컴포넌트용 전용 노드에서 이러한 Pod를 실행하기 위해 CoreDNS와 함께 node selector를 사용합니다. 그러나 selector가 노드 레이블과 일치하지 않으면 Pod는 Pending 상태로 남아 있습니다.

이 경우 CoreDNS 애드온이 기존 노드와 일치하지 않는 node selector로 구성되어 Pod가 실행되지 못했습니다.

### 해결 방법

이 문제를 해결하기 위해 CoreDNS 애드온을 기본 구성으로 업데이트하여 nodeSelector 요구 사항을 제거하겠습니다:

```bash timeout=180
$ aws eks update-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE \
    --configuration-values '{}'
{
    "update": {
        "id": "b3e7d81c-112a-33ea-bb28-1b1052bc3969",
        "status": "InProgress",
        "type": "AddonUpdate",
        "params": [
            {
                "type": "ResolveConflicts",
                "value": "OVERWRITE"
            },
            {
                "type": "ConfigurationValues",
                "value": "{}"
            }
        ],
        "createdAt": "20XX-XX-09T16:25:15.885000-05:00",
        "errors": []
    }
}
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns
```

그런 다음 CoreDNS Pod가 이제 실행 중인지 확인합니다:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-7f6dd6865f-7qcjr   1/1     Running   0          100s
CoreDNS-7f6dd6865f-kxw2x   1/1     Running   0          100s
```

마지막으로 CoreDNS 로그를 확인하여 애플리케이션이 오류 없이 실행되고 있는지 확인합니다:

```bash timeout=30
$ kubectl logs -l k8s-app=kube-dns -n kube-system
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
```

로그에 오류가 없으며, 이는 CoreDNS가 이제 DNS 요청을 올바르게 처리하고 있음을 나타냅니다.

### 다음 단계

CoreDNS Pod 스케줄링 문제를 해결하고 애플리케이션이 제대로 실행되고 있는지 확인했습니다. 추가 DNS 확인 문제 해결 단계를 위해 다음 실습으로 진행하겠습니다.
