---
title: "추가 프리픽스 사용"
sidebar_position: 40
---

워커 노드에 추가 프리픽스를 할당하는 VPC CNI의 동작을 보여주기 위해, 현재 할당된 것보다 더 많은 IP 주소를 사용하는 pause 파드를 배포할 것입니다. 배포 또는 스케일링 작업을 통해 클러스터에 애플리케이션 파드가 추가되는 것을 시뮬레이션하기 위해 많은 수의 파드를 사용합니다.

```file
manifests/modules/networking/prefix/deployment-pause.yaml
```

이것은 `150개의 파드`를 실행시킬 것이며 시간이 다소 걸릴 수 있습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/prefix
deployment.apps/pause-pods-prefix created
$ kubectl wait --for=condition=available --timeout=60s deployment/pause-pods-prefix -n other
```

pause 파드들이 실행 상태인지 확인합니다:

```bash
$ kubectl get deployment -n other
NAME                READY     UP-TO-DATE   AVAILABLE   AGE
pause-pods-prefix   150/150   150          150         101s
```

파드들이 성공적으로 실행되면, 워커 노드에 추가된 프리픽스들을 확인할 수 있습니다.

```bash
$ aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=${EKS_CLUSTER_NAME}" \
  --query 'Reservations[*].Instances[].{InstanceId: InstanceId, Prefixes: NetworkInterfaces[].Ipv4Prefixes[]}'
```

이는 VPC CNI가 특정 노드에 더 많은 파드가 스케줄링됨에 따라 ENI에 `/28` 프리픽스를 동적으로 프로비저닝하고 연결하는 방법을 보여줍니다.