---
title: "Amazon VPC CNIの設定"
sidebar_position: 30
kiteTranslationSourceHash: 56b9f4225bbc6731fdf0e409e0917f64
---

始める前に、VPC CNIがインストールされ実行されているか確認しましょう。

```bash
$ kubectl get pods --selector=k8s-app=aws-node -n kube-system
NAME             READY   STATUS    RESTARTS   AGE
aws-node-btst2   1/1     Running   0          107m
aws-node-xwkf2   1/1     Running   0          107m
aws-node-zd5rg   1/1     Running   0          107m
```

CNIのバージョンを確認します。CNIバージョンは1.9.0以降である必要があります。

```bash
$ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
amazon-k8s-cni-init:v1.12.0-eksbuild.1
amazon-k8s-cni:v1.12.0-eksbuild.1
```

上記と同様の出力が表示されるはずです。

VPC CNIがプレフィックスモードで実行されるように設定されているか確認します。`ENABLE_PREFIX_DELEGATION`の値が「true」に設定されている必要があります：

```bash
$ kubectl get ds aws-node -o yaml -n kube-system | yq '.spec.template.spec.containers[].env'
[...]
- name: ENABLE_PREFIX_DELEGATION
  value: "true"
[...]
```

プレフィックス委任が有効になっているため（このワークショップではクラスター作成時に設定されました）、ワーカーノードのネットワークインターフェースにプレフィックスが割り当てられているはずです。以下のような出力が表示されるはずです。

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

見ての通り、現在プレフィックスが私たちのワーカーノードに割り当てられています。プレフィックス委任が正常に機能しています！
