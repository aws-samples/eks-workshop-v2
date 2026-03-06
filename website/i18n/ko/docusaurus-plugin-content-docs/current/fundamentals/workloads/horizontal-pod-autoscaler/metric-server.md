---
title: "Metric server"
sidebar_position: 5
tmdTranslationSourceHash: '291842eaf4567d2355f1a79511b3836c'
---

Kubernetes Metrics Server는 클러스터의 리소스 사용 데이터 집계자이며, Amazon EKS 클러스터에는 기본적으로 배포되지 않습니다. 자세한 내용은 GitHub의 [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)를 참조하세요. Metrics Server는 Horizontal Pod Autoscaler 또는 Kubernetes Dashboard와 같은 다른 Kubernetes 애드온에서 일반적으로 사용됩니다. 자세한 내용은 Kubernetes 문서의 [Resource metrics pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)을 참조하세요.

Metrics Server는 클러스터 생성 시 EKS 커뮤니티 애드온으로 배포되었습니다:

```bash
$ kubectl -n kube-system get pod -l app.kubernetes.io/name=metrics-server
```

HPA가 스케일링 동작을 결정하는 데 사용할 메트릭을 확인하려면 `kubectl top` 명령을 사용합니다. 예를 들어, 이 명령은 클러스터의 노드 리소스 사용률을 표시합니다:

```bash
$ kubectl top node
```

Pod의 리소스 사용률도 확인할 수 있습니다. 예를 들어:

```bash
$ kubectl top pod -l app.kubernetes.io/created-by=eks-workshop -A
```

HPA가 Pod를 스케일링하는 것을 확인하면서 이러한 쿼리를 계속 사용하여 무슨 일이 일어나고 있는지 이해할 수 있습니다.

