---
title: "메트릭 서버"
sidebar_position: 5
---
Kubernetes 메트릭 서버는 클러스터의 리소스 사용량 데이터를 집계하는 도구이며, Amazon EKS 클러스터에는 기본적으로 배포되어 있지 않습니다. 자세한 내용은 GitHub의 [Kubernetes 메트릭 서버](https://github.com/kubernetes-sigs/metrics-server)를 참조하세요. 메트릭 서버는 수평적 파드 오토스케일러(HPA) 또는 Kubernetes 대시보드와 같은 다른 Kubernetes 애드온에서 일반적으로 사용됩니다. 자세한 내용은 Kubernetes 문서의 [리소스 메트릭 파이프라인](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)을 참조하세요. 이 실습에서는 Amazon EKS 클러스터에 Kubernetes 메트릭 서버를 배포할 것입니다.

이 워크샵을 위해 메트릭 서버가 우리 클러스터에 미리 설정되어 있습니다:

```bash
$ kubectl -n kube-system get pod -l app.kubernetes.io/name=metrics-server
```

HPA가 스케일링 동작을 제어하는 데 사용할 메트릭을 보려면 `kubectl top` 명령을 사용하세요. 예를 들어, 다음 명령은 우리 클러스터의 노드 리소스 사용량을 보여줍니다:

```bash
$ kubectl top node
```

또한 다음과 같이 파드의 리소스 사용량도 확인할 수 있습니다:

```bash
$ kubectl top pod -l app.kubernetes.io/created-by=eks-workshop -A
```

HPA가 파드를 스케일링하는 것을 보면서 이러한 쿼리들을 계속 사용하여 무슨 일이 일어나고 있는지 이해할 수 있습니다.
