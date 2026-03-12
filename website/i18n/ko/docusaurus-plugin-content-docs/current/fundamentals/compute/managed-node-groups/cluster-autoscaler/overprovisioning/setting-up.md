---
title: "오버 프로비저닝 설정"
sidebar_position: 35
tmdTranslationSourceHash: 'c3d3a0fcb9b4afc81fd1b6078f840900'
---

오버 프로비저닝을 효과적으로 구현하려면 애플리케이션에 적합한 `PriorityClass` 리소스를 생성하는 것이 모범 사례로 간주됩니다. `globalDefault: true` 필드를 사용하여 전역 기본 우선순위 클래스를 생성하는 것부터 시작하겠습니다. 이 기본 `PriorityClass`는 `PriorityClassName`을 지정하지 않은 Pod와 배포에 할당됩니다.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-default.yaml" paths="value,globalDefault"}

1. 값은 필수 `value` 필드에 지정됩니다. 값이 높을수록 우선순위가 높습니다.
2. `globalDefault` 필드는 이 PriorityClass의 값이 priorityClassName이 없는 Pod에 사용되어야 함을 나타냅니다.

다음으로, 오버 프로비저닝에 사용되는 pause Pod를 위해 우선순위 값이 `-1`인 `PriorityClass`를 생성하겠습니다.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/priorityclass-pause.yaml" paths="value"}

1. "-1"의 우선순위 값은 빈 "pause" 컨테이너가 플레이스홀더 역할을 할 수 있도록 합니다. 실제 워크로드가 스케줄링되면 빈 플레이스홀더 컨테이너가 축출되어 애플리케이션 Pod를 즉시 프로비저닝할 수 있습니다.

Pause Pod는 환경에 필요한 오버 프로비저닝 양에 따라 사용 가능한 노드가 충분히 있도록 하는 데 중요한 역할을 합니다. Cluster Autoscaler는 ASG에 지정된 이 최대값을 초과하여 노드 수를 늘리지 않으므로 EKS 노드 그룹의 ASG에서 `--max-size` 파라미터를 염두에 두는 것이 중요합니다.

::yaml{file="manifests/modules/autoscaling/compute/overprovisioning/setup/deployment-pause.yaml" paths="spec.replicas,spec.template.spec.priorityClassName"}

1. pause Pod의 복제본 2개를 배포합니다
2. 이전에 생성한 우선순위 클래스를 사용합니다

이러한 Pod는 각각 `6.5Gi`의 메모리를 요청하므로 거의 전체 `m5.large` 인스턴스를 소비하여 항상 두 개의 "예비" 워커 노드를 사용할 수 있게 됩니다.

이러한 업데이트를 클러스터에 적용해 보겠습니다:

```bash timeout=340 hook=overprovisioning-setup
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
priorityclass.scheduling.k8s.io/default created
priorityclass.scheduling.k8s.io/pause-pods created
deployment.apps/pause-pods created
$ kubectl rollout status -n other deployment/pause-pods --timeout 300s
```

이 프로세스가 완료되면 pause Pod가 실행됩니다:

```bash
$ kubectl get pods -n other
NAME                          READY   STATUS    RESTARTS   AGE
pause-pods-7f7669b6d7-v27sl   1/1     Running   0          5m6s
pause-pods-7f7669b6d7-v7hqv   1/1     Running   0          5m6s
```

이제 Cluster Autoscaler에 의해 추가 노드가 프로비저닝된 것을 관찰할 수 있습니다:

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

이 두 개의 추가 노드는 pause Pod를 제외한 어떤 워크로드도 실행하지 않으며, "실제" 워크로드가 스케줄링되면 축출됩니다.

