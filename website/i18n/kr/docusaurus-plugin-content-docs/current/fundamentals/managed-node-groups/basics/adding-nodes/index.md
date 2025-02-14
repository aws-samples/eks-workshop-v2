---
title: 노드 추가
sidebar_position: 10
---
클러스터 작업 중에 워크로드의 요구 사항을 지원하기 위해 추가 노드를 추가하도록 관리형 노드 그룹 구성을 업데이트해야 할 수 있습니다. 노드 그룹을 확장하는 방법은 여러 가지가 있는데, 우리의 경우 `aws eks update-nodegroup-config` 명령을 사용할 것입니다.

먼저 아래 `eksctl` 명령을 사용하여 현재 노드그룹 스케일링 구성을 검색하고 노드의 **최소 크기**, **최대 크기** 및 **원하는 용량**을 살펴보겠습니다:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

아래 명령을 사용하여 `eks-workshop`의 노드그룹의 **원하는 용량**을 `3`에서 `4`로 변경하여 스케일링하겠습니다:

```bash
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=4,maxSize=6,desiredSize=4
```

노드 그룹을 변경한 후 노드 프로비저닝 및 구성 변경이 적용되는 데 최대 **2-3분**이 걸릴 수 있습니다. 아래 `eksctl` 명령을 사용하여 노드그룹 구성을 다시 검색하고 노드의 **최소 크기**, **최대 크기** 및 **원하는 용량**을 살펴보겠습니다:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

4개의 노드가 될 때까지 `--watch` 인수를 사용하여 다음 명령으로 클러스터의 노드를 모니터링합니다:

:::tip
아래 출력에 노드가 나타나는 데 1분 정도 걸릴 수 있습니다. 목록에 아직 3개의 노드가 표시되면 기다려주세요.
:::

```bash
$ kubectl get nodes --watch
NAME                                          STATUS     ROLES    AGE  VERSION
ip-10-42-104-151.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-144-11.us-west-2.compute.internal    Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-146-166.us-west-2.compute.internal   NotReady   <none>   18s  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-182-134.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
```

4개의 노드가 보이면 `Ctrl+C`를 사용하여 watch를 종료할 수 있습니다.

새 노드가 아직 클러스터에 조인하는 과정 중일 때 발생하는 `NotReady` 상태의 노드가 보일 수 있습니다.
