---
title: "추가 Prefix 사용"
sidebar_position: 40
tmdTranslationSourceHash: '22035f7491caa38d7039b931d8b3c95f'
---

워커 노드에 추가 Prefix를 추가하는 VPC CNI 동작을 시연하기 위해, 현재 할당된 것보다 더 많은 IP 주소를 사용하기 위해 pause Pod들을 배포하겠습니다. 이러한 많은 수의 Pod를 활용하여 배포나 스케일링 작업을 통해 클러스터에 애플리케이션 Pod가 추가되는 상황을 시뮬레이션합니다.

::yaml{file="manifests/modules/networking/prefix/deployment-pause.yaml" paths="spec.replicas,spec.template.spec.containers.0.image"}

1. 150개의 동일한 Pod 생성
2. 최소한의 리소스를 사용하는 경량 컨테이너를 제공하는 `registry.k8s.io/pause` 이미지 설정

pause Pod 배포를 적용하고 준비될 때까지 기다립니다. `150개의 Pod`를 시작하는 데 시간이 걸릴 수 있습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/prefix
deployment.apps/pause-pods-prefix created
$ kubectl wait --for=condition=available --timeout=60s deployment/pause-pods-prefix -n other
```

pause Pod들이 실행 상태인지 확인합니다:

```bash
$ kubectl get deployment -n other
NAME                READY     UP-TO-DATE   AVAILABLE   AGE
pause-pods-prefix   150/150   150          150         101s
```

Pod들이 성공적으로 실행되면, 워커 노드에 추가된 추가 Prefix를 확인할 수 있습니다.

```bash
$ aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=${EKS_CLUSTER_NAME}" \
  --query 'Reservations[*].Instances[].{InstanceId: InstanceId, Prefixes: NetworkInterfaces[].Ipv4Prefixes[]}'
```

이는 VPC CNI가 특정 노드에 더 많은 Pod가 스케줄링됨에 따라 ENI에 `/28` Prefix를 동적으로 프로비저닝하고 연결하는 방법을 보여줍니다.

