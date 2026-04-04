---
title: "NotReady 상태의 노드"
sidebar_position: 73
chapter: true
tmdTranslationSourceHash: 09464da5ad3fd035147d80e84aa037dc
---

::required-time

### 배경

Corporation XYZ의 DevOps 팀은 새로운 노드 그룹을 배포했고, 애플리케이션 팀은 retail-app 외부에 새로운 애플리케이션을 배포했습니다. 여기에는 Deployment(prod-app)와 이를 지원하는 DaemonSet(prod-ds)이 포함됩니다.

이러한 애플리케이션을 배포한 후, 모니터링 팀은 노드가 **_NotReady_** 상태로 전환되고 있다고 보고했습니다. 근본 원인이 즉시 명확하지 않으며, 당직 DevOps 엔지니어로서 노드가 응답하지 않는 이유를 조사하고 정상 작동을 복원하기 위한 솔루션을 구현해야 합니다.

### Step 1: 노드 상태 확인

먼저 노드의 상태를 확인하여 현재 상태를 확인해 보겠습니다:

```bash timeout=40 hook=fix-3-1 hookTimeout=60 wait=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS     ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   NotReady   <none>   15m     v1.27.1-eks-2f008fe
```

### Step 2: 노드 이름 내보내기

```bash
$ NODE_NAME=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 --no-headers | awk '{print $1}' | head -1)
```

### Step 3: 시스템 Pod 상태 확인

시스템 수준의 문제를 식별하기 위해 영향을 받는 노드의 kube-system Pod 상태를 살펴보겠습니다:

```bash
$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=$NODE_NAME
```

이 명령은 영향을 받는 노드에서 실행 중인 모든 kube-system Pod를 보여주며, 이러한 Pod로 인한 노드의 잠재적 문제를 식별하는 데 도움이 됩니다. 모든 Pod가 실행 중 상태임을 확인해야 합니다.

### Step 4: 노드 Conditions 검토

_NotReady_ 상태의 원인을 이해하기 위해 노드의 describe 출력을 살펴보겠습니다.

```bash
$ kubectl describe node $NODE_NAME | sed -n '/^Taints:/,/^[A-Z]/p;/^Conditions:/,/^[A-Z]/p;/^Events:/,$p'


Taints:             node.kubernetes.io/unreachable:NoExecute
                    node.kubernetes.io/unreachable:NoSchedule
Unschedulable:      false
Conditions:
  Type             Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----             ------    -----------------                 ------------------                ------              -------
  MemoryPressure   Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure     Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure      Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready            Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
Addresses:
Events:
  Type     Reason                   Age                    From                     Message
  ----     ------                   ----                   ----                     -------
  Normal   Starting                 3m18s                  kube-proxy
  Normal   Starting                 3m31s                  kubelet                  Starting kubelet.
  Warning  InvalidDiskCapacity      3m31s                  kubelet                  invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientPID
  Normal   NodeAllocatableEnforced  3m31s                  kubelet                  Updated Node Allocatable limit across pods
  Normal   RegisteredNode           3m27s                  node-controller          Node ip-10-42-180-244.us-west-2.compute.internal event: Registered Node ip-10-42-180-244.us-west-2.compute.internal in Controller
  Normal   Synced                   3m27s                  cloud-node-controller    Node synced successfully
  Normal   ControllerVersionNotice  3m12s                  vpc-resource-controller  The node is managed by VPC resource controller version v1.6.3
  Normal   NodeReady                3m10s                  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeReady
  Normal   NodeTrunkInitiated       3m8s                   vpc-resource-controller  The node has trunk interface initialized successfully
  Warning  SystemOOM                94s                    kubelet                  System OOM encountered, victim process: python, pid: 4763
  Normal   NodeNotReady             52s                    node-controller          Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeNotReady
```

여기서 노드의 kubelet이 _Unknown_ 상태에 있으며 연결할 수 없음을 알 수 있습니다. 이 상태에 대한 자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/reference/node/node-status/#condition)에서 확인할 수 있습니다.

:::note 노드 상태 정보
노드에는 다음과 같은 Taint가 있습니다:

- **node.kubernetes.io/unreachable:NoExecute**: 이 Taint를 허용하지 않는 Pod는 제거됨을 나타냅니다
- **node.kubernetes.io/unreachable:NoSchedule**: 새로운 Pod가 스케줄링되는 것을 방지합니다

노드 Conditions는 kubelet이 상태 업데이트 게시를 중단했음을 보여주며, 이는 일반적으로 심각한 리소스 제약이나 시스템 불안정을 나타낼 수 있습니다.
:::

### Step 5: CloudWatch Metrics 조사

Metrics Server가 데이터를 제공하지 않으므로 CloudWatch를 사용하여 EC2 인스턴스 메트릭을 확인해 보겠습니다:

:::info
편의를 위해 new_nodegroup_3의 워커 노드 인스턴스 ID가 환경 변수 $INSTANCE_ID로 저장되어 있습니다.
:::

```bash
$ aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'

{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT16:25:00+00:00",
                "2025-0X-XXT16:20:00+00:00",
                "2025-0X-XXT16:15:00+00:00",
                "2025-0X-XXT16:10:00+00:00"
            ],
            "Values": [
                99.87333333333333,
                99.89633636636336,
                99.86166666666668,
                62.67880324995537
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```

:::info
CloudWatch 메트릭은 다음을 보여줍니다:

- CPU 사용률이 지속적으로 99% 이상
- 시간이 지남에 따라 리소스 사용량이 크게 증가
- 리소스 고갈의 명확한 징후

:::

### Step 6: 영향 완화

Deployment 세부 정보를 확인하고 노드를 안정화하기 위한 즉각적인 변경을 구현해 보겠습니다:

#### 6.1. Deployment 리소스 구성 확인

```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-74b97f9d85-k6c84   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-mpcrv   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-wdqlr   100m          64Mi          <none>      <none>
...
...
prod-ds-558sx               100m          128Mi         <none>      <none>
```

:::info
Deployment와 DaemonSet 모두 리소스 제한이 구성되어 있지 않으므로 무제한 리소스 소비가 가능했습니다.
:::

#### 6.2. Deployment를 스케일 다운하여 리소스 과부하 중지

```bash bash timeout=40 wait=25
$ kubectl scale deployment/prod-app -n prod --replicas=0 && kubectl delete pod -n prod -l app=prod-app --force --grace-period=0 && kubectl wait --for=delete pod -n prod -l app=prod-app
```

#### 6.3. 노드 그룹의 노드 재시작

```bash timeout=120 wait=95
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=0 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --labels "addOrUpdateLabels={status=new-node}" && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=1 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
for i in {1..12}; do NODE_NAME_2=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3,status=new-node --no-headers -o custom-columns=":metadata.name" 2>/dev/null) && [ -n "$NODE_NAME_2" ] && break || sleep 5; done && \
[ -n "$NODE_NAME_2" ]
```

:::info
이 작업은 1분 조금 넘게 걸릴 수 있습니다. 스크립트는 새 노드 이름을 NODE_NAME_2로 저장합니다.
:::

#### 6.4. 노드 상태 확인

```bash test=false
$ kubectl get nodes --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   0h43m   v1.30.8-eks-aeac579
```

### Step 7: 장기적인 솔루션 구현

개발 팀이 애플리케이션의 메모리 누수를 식별하고 수정했습니다. 수정 사항을 구현하고 적절한 리소스 관리를 설정해 보겠습니다:

#### 7.1. 업데이트된 애플리케이션 구성 적용

```bash timeout=10 wait=5
$ kubectl apply -f /home/ec2-user/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/configmaps-new.yaml
```

#### 7.2. Deployment에 대한 리소스 제한 설정 (cpu: 500m, memory: 512Mi)

```bash timeout=10 wait=5
$ kubectl patch deployment prod-app -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-app","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.3. DaemonSet에 대한 리소스 제한 설정 (cpu: 500m, memory: 512Mi)

```bash timeout=10 wait=5
$ kubectl patch daemonset prod-ds -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-ds","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.4. 롤링 업데이트 수행 및 원하는 상태로 스케일 복원

```bash timeout=20 wait=10
$ kubectl rollout restart deployment/prod-app -n prod && kubectl rollout restart daemonset/prod-ds -n prod && kubectl scale deployment prod-app -n prod --replicas=6
```

### Step 8: 검증

수정 사항이 문제를 해결했는지 확인해 보겠습니다:

#### 8.1 Pod 생성 확인

```bash test=false
$ kubectl get pods -n prod
NAME                        READY   STATUS    RESTARTS   AGE
prod-app-666f8f7bd5-658d6   1/1     Running   0          1m
prod-app-666f8f7bd5-6jrj4   1/1     Running   0          1m
prod-app-666f8f7bd5-9rf6m   1/1     Running   0          1m
prod-app-666f8f7bd5-pm545   1/1     Running   0          1m
prod-app-666f8f7bd5-ttkgs   1/1     Running   0          1m
prod-app-666f8f7bd5-zm8lx   1/1     Running   0          1m
prod-ds-ll4lv               1/1     Running   0          1m
```

#### 8.2. Pod 제한 확인
```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-6d67889dc8-4hc7m   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-6s8wr   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-fd6kq   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-gzcbn   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-qvtvj   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-rf478   250m          256Mi         500m        512Mi
prod-ds-srdqx               250m          256Mi         500m        512Mi
```

#### 8.3 노드 CPU 리소스 확인
```bash wait=300 test=false
$ INSTANCE_ID=$(kubectl get node ${NODE_NAME_2} -o jsonpath='{.spec.providerID}' | cut -d '/' -f5) && aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'
{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT18:30:00+00:00",
                "2025-0X-XXT18:25:00+00:00"
            ],
            "Values": [
                88.05,
                58.63008430846801
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```
:::info
CPU가 과도하게 사용되지 않는지 확인합니다.
:::
#### 8.4. 노드 상태 확인

```bash
$ kubectl get node --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   1h35m   v1.30.8-eks-aeac579
```

### 주요 사항

#### 1. 리소스 관리

- 항상 적절한 리소스 요청 및 제한 설정
- 누적 워크로드 영향 모니터링
- 적절한 리소스 할당량 구현

#### 2. 모니터링

- 여러 모니터링 도구 사용
- 사전 알림 설정
- 컨테이너 및 노드 수준 메트릭 모두 모니터링

#### 3. 모범 사례

- Horizontal Pod Autoscaling 구현
- 오토스케일링 사용: [Cluster-autoscaler](https://docs.aws.amazon.com/eks/latest/best-practices/cas.html), [Karpenter](https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html), [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- 정기적인 용량 계획
- 애플리케이션에서 적절한 오류 처리 구현

### 추가 리소스

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Out of Resource Handling](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-EKS.html)
- [Knowledge Center Guide](https://repost.aws/knowledge-center/eks-node-status-ready)

