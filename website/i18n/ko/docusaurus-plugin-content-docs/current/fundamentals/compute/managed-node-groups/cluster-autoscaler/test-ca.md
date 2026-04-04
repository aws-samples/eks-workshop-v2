---
title: "CA로 스케일링"
sidebar_position: 40
tmdTranslationSourceHash: '88e30a6e724cb75c453a0a55ad3c9524'
---

이 섹션에서는 모든 애플리케이션 컴포넌트의 레플리카 수를 4로 증가시킵니다. 이렇게 하면 클러스터에서 사용 가능한 것보다 더 많은 리소스가 소비되어 더 많은 컴퓨팅 리소스가 프로비저닝됩니다.

```file
manifests/modules/autoscaling/compute/cluster-autoscaler/deployment.yaml
```

클러스터에 적용해 보겠습니다:

```bash hook=ca-pod-scaleout timeout=180
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/cluster-autoscaler
```

일부 Pod는 `Pending` 상태가 되며, 이는 cluster-autoscaler가 EC2 플릿을 스케일 아웃하도록 트리거합니다.

```bash test=false
$ kubectl get pods -A -o wide --watch
```

cluster-autoscaler 로그를 확인합니다:

```bash test=false
$ kubectl -n kube-system logs \
  -f deployment/cluster-autoscaler-aws-cluster-autoscaler
```

새 노드를 추가하기 위한 스케일 아웃 이벤트를 나타내는 cluster-autoscaler가 생성한 다음과 유사한 로그를 볼 수 있습니다:

```text
...
...
I0411 21:26:52.108599       1 klogx.go:87] Pod ui/ui-68495c748c-dbh22 is unschedulable
I0411 21:26:52.108604       1 klogx.go:87] Pod ui/ui-68495c748c-98gcq is unschedulable
I0411 21:26:52.108608       1 klogx.go:87] Pod ui/ui-68495c748c-8pkdv is unschedulable
I0411 21:26:52.108903       1 orchestrator.go:108] Upcoming 0 nodes
I0411 21:26:52.109318       1 orchestrator.go:181] Best option to resize: eks-default-62c766f6-ec38-5423-ce6a-c4633f142631
I0411 21:26:52.109334       1 orchestrator.go:185] Estimated 1 nodes needed in eks-default-62c766f6-ec38-5423-ce6a-c4633f142631
I0411 21:26:52.109358       1 orchestrator.go:291] Final scale-up plan: [{eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 3->4 (max: 6)}]
I0411 21:26:52.109376       1 executor.go:147] Scale-up: setting group eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 size to 4
I0411 21:26:52.109428       1 auto_scaling_groups.go:267] Setting asg eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 size to 4
...
...
```

[EC2 AWS Management Console](https://console.aws.amazon.com/ec2/home?#Instances:sort=instanceId)을 확인하여 Auto Scaling 그룹이 수요를 충족하기 위해 스케일 업되고 있는지 확인합니다. 이 작업은 몇 분 정도 걸릴 수 있습니다. 명령줄에서 Pod 배포를 따라갈 수도 있습니다. 노드가 스케일 업됨에 따라 Pod가 pending에서 running으로 전환되는 것을 확인할 수 있습니다.

또는 `kubectl`을 사용할 수 있습니다:

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   vVAR::KUBERNETES_NODE_VERSION
```

