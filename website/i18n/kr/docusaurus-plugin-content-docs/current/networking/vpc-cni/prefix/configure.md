---
title: "Amazon VPC CNI 구성"
sidebar_position: 30
---

시작하기 전에, VPC CNI가 설치되어 실행 중인지 확인해보겠습니다.

```bash
$ kubectl get pods --selector=k8s-app=aws-node -n kube-system
NAME             READY   STATUS    RESTARTS   AGE
aws-node-btst2   1/1     Running   0          107m
aws-node-xwkf2   1/1     Running   0          107m
aws-node-zd5rg   1/1     Running   0          107m
```

CNI 버전을 확인합니다. CNI 버전은 1.9.0 이상이어야 합니다.

```bash
$ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
amazon-k8s-cni-init:v1.12.0-eksbuild.1
amazon-k8s-cni:v1.12.0-eksbuild.1
```

위와 유사한 출력을 보게 될 것입니다.

VPC CNI가 프리픽스 모드로 실행되도록 구성되어 있는지 확인합니다. `ENABLE_PREFIX_DELEGATION` 값이 "true"로 설정되어 있어야 합니다:

```bash
$ kubectl get ds aws-node -o yaml -n kube-system | yq '.spec.template.spec.containers[].env'
[...]
- name: ENABLE_PREFIX_DELEGATION
  value: "true"
[...]
```

프리픽스 위임이 활성화되어 있으므로(이 워크샵에서는 클러스터 생성 시 설정됨), 워커 노드의 네트워크 인터페이스에 할당된 프리픽스를 볼 수 있어야 합니다. 아래와 유사한 출력을 보게 될 것입니다.

```bash
$ aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" \
  "Name=tag-value,Values=${EKS_CLUSTER_NAME}" \
  --query 'Reservations[*].Instances[].{InstanceId: InstanceId, Prefixes: NetworkInterfaces[].Ipv4Prefixes[]}'

 [
    {
        "InstanceId": "i-0d1f7c060cf3ad0f4",
        "Prefixes": [
            {
                "Ipv4Prefix": "10.42.10.192/28"
            },
            {
                "Ipv4Prefix": "10.42.10.80/28"
            }
        ]
    },
    {
        "InstanceId": "i-0b47d3070af05c8b1",
        "Prefixes": [
            {
                "Ipv4Prefix": "10.42.10.16/28"
            },
            {
                "Ipv4Prefix": "10.42.10.160/28"
            }
        ]
    },
    {
        "InstanceId": "i-081b2a4d4e5f27991",
        "Prefixes": [
            {
                "Ipv4Prefix": "10.42.12.128/28"
            },
            {
                "Ipv4Prefix": "10.42.12.208/28"
            }
        ]
    }
]
```

보시다시피, 현재 우리의 워커 노드에 프리픽스가 할당되어 있습니다. 프리픽스 위임이 성공적으로 작동하고 있습니다!