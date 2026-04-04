---
title: "오토스케일링 트리거"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 3
tmdTranslationSourceHash: 'be868c3a133b355f49a3c6cc792b5a76'
---

이전 섹션에서 설치한 Cluster Proportional Autoscaler(CPA)를 테스트해 보겠습니다. 현재 3개의 노드로 구성된 클러스터를 실행하고 있습니다:

```bash
$ kubectl get nodes
NAME                                            STATUS   ROLES    AGE   VERSION
ip-10-42-109-155.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-142-113.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-80-39.us-east-2.compute.internal       Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
```

구성에서 정의한 오토스케일링 파라미터에 따라, CPA가 CoreDNS를 2개의 replica로 스케일한 것을 확인할 수 있습니다:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-5zwws   1/1     Running   0          66s
coredns-5db97b446d-n5mp4   1/1     Running   0          89m
```

EKS 클러스터의 크기를 5개 노드로 증가시키면, Cluster Proportional Autoscaler가 추가된 노드를 수용하기 위해 CoreDNS replica 수를 자동으로 스케일 업합니다:

```bash hook=cpa-pod-scaleout timeout=300
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config desiredSize=$(($EKS_DEFAULT_MNG_DESIRED+2))
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME
$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
```

이제 Kubernetes는 모든 5개의 노드가 `Ready` 상태임을 보여줍니다:

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-10-248.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-29.us-west-2.compute.internal     Ready    <none>   124m  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-109.us-west-2.compute.internal    Ready    <none>   6m39s vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-152.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-139.us-west-2.compute.internal    Ready    <none>   6m20s vVAR::KUBERNETES_NODE_VERSION
```

그리고 2개의 노드당 1개의 replica를 설정한 구성에 따라 CoreDNS Pod의 수가 3개로 증가한 것을 확인할 수 있습니다:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-657694c6f4-klj6w   1/1     Running   0          14h
coredns-657694c6f4-tdzsd   1/1     Running   0          54s
coredns-657694c6f4-wmnnc   1/1     Running   0          14h
```

CPA 로그를 살펴보면 클러스터의 노드 수 변경에 어떻게 대응했는지 확인할 수 있습니다:

```bash
$ kubectl logs deployment/cluster-proportional-autoscaler -n kube-system
{"includeUnschedulableNodes":true,"max":6,"min":2,"nodesPerReplica":2,"preventSinglePointFailure":true}
I0801 15:02:45.330307       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:02:45.330328       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 2 to 3
```

로그를 통해 CPA가 클러스터 크기 변경을 감지하고 그에 따라 CoreDNS replica 수를 조정했음을 확인할 수 있습니다.

