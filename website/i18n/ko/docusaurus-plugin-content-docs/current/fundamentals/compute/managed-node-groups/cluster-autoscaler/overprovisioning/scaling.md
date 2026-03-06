---
title: "추가 스케일링"
sidebar_position: 50
tmdTranslationSourceHash: '860ea9f5106b50857abe6239ba4ce69e'
---

이 실습에서는 Cluster Autoscaler 섹션에서 이전에 수행한 것보다 더 많이 전체 애플리케이션 아키텍처를 확장하고 응답성이 어떻게 다른지 관찰합니다.

다음 구성 파일이 적용되어 애플리케이션 컴포넌트를 확장합니다:

```file
manifests/modules/autoscaling/compute/overprovisioning/scale/deployment.yaml
```

클러스터에 이러한 업데이트를 적용해 보겠습니다:

```bash timeout=180 hook=overprovisioning-scale
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/scale
$ kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
```

새 Pod가 롤아웃되면서, pause Pod가 워크로드 서비스가 활용할 수 있는 리소스를 소비하는 충돌이 결국 발생합니다. 우리의 우선순위 구성으로 인해, pause Pod는 워크로드 Pod가 시작할 수 있도록 제거됩니다. 이로 인해 일부 또는 모든 pause Pod가 `Pending` 상태가 됩니다:

```bash
$ kubectl get pod -n other -l run=pause-pods
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   0/1     Pending   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
```

이 제거 프로세스를 통해 워크로드 Pod가 `ContainerCreating` 및 `Running` 상태로 더 빠르게 전환되어 클러스터 오버프로비저닝의 이점을 보여줍니다.

그런데 왜 이 Pod들이 이제 pending 상태일까요? Cluster Autoscaler가 추가 노드를 프로비저닝해야 하지 않을까요? 답은 클러스터에 구성된 Managed Node Group의 최대 크기가 `6`이라는 것인데, 이는 실습 클러스터의 인스턴스 수 제한에 도달했음을 의미합니다.

