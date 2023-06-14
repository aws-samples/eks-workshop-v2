---
title: "Configure Amazon VPC CNI"
sidebar_position: 30
---

Before we begin, lets confirm if the VPC CNI is installed and running.

```bash
$ kubectl get pods --selector=k8s-app=aws-node -n kube-system
NAME             READY   STATUS    RESTARTS   AGE
aws-node-btst2   1/1     Running   0          107m
aws-node-xwkf2   1/1     Running   0          107m
aws-node-zd5rg   1/1     Running   0          107m
```

Confirm the CNI version. The CNI version must be 1.9.0 or later.

```bash
$ kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
amazon-k8s-cni-init:v1.12.0-eksbuild.1
amazon-k8s-cni:v1.12.0-eksbuild.1
```

You will see similar output to above.

Confirm if the VPC CNI is configured to run in prefix mode. The `ENABLE_PREFIX_DELEGATION` value should be set to "true":

```bash
$ kubectl get ds aws-node -o yaml -n kube-system | yq '.spec.template.spec.containers[].env'
[...]
- name: ENABLE_PREFIX_DELEGATION
  value: "true"
[...]
```

Since prefix delegation is enabled (this was done at cluster creation for this workshop), we should be able to see prefix assigned to the network interfaces of the worker nodes. You should see output similar to below.

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

As we can see, there are currently prefixes assigned to our worker nodes. Prefix delegation is working successfully!
