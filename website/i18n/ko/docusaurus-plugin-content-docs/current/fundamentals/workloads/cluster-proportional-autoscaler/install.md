---
title: "CoreDNS 오토스케일링"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 2
tmdTranslationSourceHash: '43f85cae9190a6925d7ae670d98ded21'
---

CoreDNS는 Kubernetes의 기본 DNS 서비스로, `k8s-app=kube-dns` 레이블이 있는 Pod에서 실행됩니다. 이 실습에서는 클러스터의 스케줄 가능한 노드와 코어 수를 기반으로 CoreDNS를 스케일링합니다. Cluster Proportional Autoscaler가 CoreDNS 레플리카 수를 조정합니다.

:::info

Amazon EKS는 [EKS 애드온을 통해 CoreDNS를 자동으로 스케일링](https://docs.aws.amazon.com/eks/latest/userguide/coredns-autoscaling.html)하는 기능을 제공하며, 이는 프로덕션 사용을 위한 권장 방법입니다. 이 실습에서 다루는 내용은 교육 목적입니다.

:::

먼저 Helm 차트를 사용하여 CPA를 설치하겠습니다. 다음 `values.yaml` 파일을 사용하여 CPA를 구성합니다:

::yaml{file="manifests/modules/autoscaling/workloads/cpa/values.yaml" paths="options.target,config.linear.nodesPerReplica,config.linear.min,config.linear.max"}

구성 설명:

1. `coredns` Deployment를 대상으로 합니다
2. 클러스터의 워커 노드 2개당 레플리카 1개를 추가합니다
3. 항상 최소 2개의 레플리카를 실행합니다
4. 최대 6개의 레플리카를 초과하여 스케일링하지 않습니다

:::caution

위의 구성은 CoreDNS를 자동으로 스케일링하기 위한 모범 사례로 간주되어서는 안 됩니다. 워크샵 목적상 시연하기 쉬운 예시입니다.

:::

차트를 설치하겠습니다:

```bash
$ helm repo add cluster-proportional-autoscaler https://kubernetes-sigs.github.io/cluster-proportional-autoscaler
$ helm upgrade --install cluster-proportional-autoscaler cluster-proportional-autoscaler/cluster-proportional-autoscaler \
  --namespace kube-system \
  --version "${CPA_CHART_VERSION}" \
  --set "image.tag=v${CPA_VERSION}" \
  --values ~/environment/eks-workshop/modules/autoscaling/workloads/cpa/values.yaml \
  --wait
NAME: cluster-proportional-autoscaler
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

이렇게 하면 `kube-system` 네임스페이스에 `Deployment`가 생성되며, 다음과 같이 확인할 수 있습니다:

```bash
$ kubectl get deployment cluster-proportional-autoscaler -n kube-system
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
cluster-proportional-autoscaler   1/1     1            1           92s
```

