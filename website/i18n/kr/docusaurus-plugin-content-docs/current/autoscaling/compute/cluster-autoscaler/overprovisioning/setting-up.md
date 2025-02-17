---
title: "오버 프로비저닝 설정하기"
sidebar_position: 35
---
오버 프로비저닝을 효과적으로 구현하기 위해서는 애플리케이션에 적절한 `PriorityClass` 리소스를 생성하는 것이 모범 사례로 간주됩니다. `globalDefault: true` 필드를 사용하여 전역 기본 우선순위 클래스를 생성하는 것부터 시작하겠습니다. 이 기본 `PriorityClass`는 `PriorityClassName`을 지정하지 않은 파드와 디플로이먼트에 할당됩니다.

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml
```

다음으로, 오버 프로비저닝에 사용되는 일시 중지 파드를 위한 `PriorityClass`를 생성하겠습니다. 이 우선순위 값은 `-1`로 설정됩니다.

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml
```

일시 중지 파드는 환경에 필요한 오버 프로비저닝 양에 따라 충분한 노드를 확보하는 데 중요한 역할을 합니다. EKS 노드 그룹의 ASG에서 `--max-size` 파라미터를 고려하는 것이 중요합니다. Cluster Autoscaler(CA)는 ASG에 지정된 이 최대값을 초과하여 노드 수를 증가시키지 않습니다.

```file
manifests/modules/autoscaling/compute/overprovisioning/setup/deployment-pause.yaml
```

이 시나리오에서는 `6.5Gi`의 메모리를 요청하는 단일 일시 중지 파드를 스케줄링할 것입니다. 이는 거의 전체 `m5.large` 인스턴스를 소비하게 되어, 항상 두 개의 "여분의" 워커 노드를 사용할 수 있게 됩니다.

클러스터에 이러한 업데이트를 적용해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
priorityclass.scheduling.k8s.io/default created
priorityclass.scheduling.k8s.io/pause-pods created
deployment.apps/pause-pods created
$ kubectl rollout status -n other deployment/pause-pods --timeout 300s
```

이 프로세스가 완료되면 일시 중지 파드가 실행됩니다:

```bash
$ kubectl get pods -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-7f7669b6d7-v27sl   1/1     Running   0          5m6s
pause-pods-7f7669b6d7-v7hqv   1/1     Running   0          5m6s
```

이제 Cluster Autoscaler에 의해 추가 노드가 프로비저닝된 것을 확인할 수 있습니다:

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-111.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-133.us-west-2.compute.internal   Ready    <none>   33s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   vVAR::KUBERNETES_NODE_VERSION
```

이 두 개의 추가 노드는, 일시 중지 파드 외에는 어떤 워크로드도 실행하지 않으며, "실제" 워크로드가 스케줄링될 때 퇴거(evict)됩니다.
