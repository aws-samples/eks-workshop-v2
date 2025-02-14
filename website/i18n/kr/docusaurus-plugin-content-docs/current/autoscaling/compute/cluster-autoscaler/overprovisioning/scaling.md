---
title: "추가 확장"
sidebar_position: 50
---
이 실습에서는, 이전 클러스터 오토스케일러 섹션에서 다룬 것보다 더 큰 규모로, 전체 애플리케이션 아키텍처를 확장하고 응답성이 어떻게 달라지는지 관찰할 것입니다.

다음 구성 파일이 애플리케이션 구성 요소를 확장하기 위해 적용될 것입니다:

```file
manifests/modules/autoscaling/compute/overprovisioning/scale/deployment.yaml
```

이제 이 업데이트를 클러스터에 적용해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/scale
$ kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
```

새로운 파드가 배포되면서, 결국 `pause-pods`가 워크로드 서비스가 사용할 수 있는 리소스를 소비하는 충돌이 발생할 것입니다. 우리의 우선순위 구성으로 인해, pause 파드는 워크로드 파드가 시작될 수 있도록 퇴출될 것입니다. 이로 인해 일부 또는 모든 pause 파드가 `Pending` 상태가 될 것입니다:

```bash
$ kubectl get pod -n other -l run=pause-pods
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-5556d545f7-2pt9g   0/1     Pending   0          16m
pause-pods-5556d545f7-k5vj7   0/1     Pending   0          16m
```

이러한 퇴출 프로세스를 통해 워크로드 파드가 더 빠르게 `ContainerCreating`과 `Running` 상태로 전환될 수 있으며, 이는 클러스터 오버프로비저닝의 이점을 보여줍니다.
