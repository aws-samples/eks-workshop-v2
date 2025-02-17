---
title: "aws-auth 신원 매핑에서 마이그레이션"
sidebar_position: 20
---

이미 EKS를 사용하고 있는 고객은 클러스터 접근을 관리하기 위해 `aws-auth` ConfigMap 메커니즘을 사용하고 있을 수 있습니다. 이 섹션에서는 이전 메커니즘에서 클러스터 접근 항목을 사용하는 방식으로 마이그레이션하는 방법을 보여줍니다.

EKS 관리자 권한을 가진 그룹을 위해 `eks-workshop-admins` IAM 역할이 EKS 클러스터에 사전 구성되어 있습니다. `aws-auth` ConfigMap을 확인해 보겠습니다:

```bash
$ kubectl --context default get -o yaml -n kube-system cm aws-auth
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::1234567890:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-acgt4WAVfXAA
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::1234567890:role/eks-workshop-admins
      username: cluster-admin
  mapUsers: |
    []
kind: ConfigMap
metadata:
  creationTimestamp: "2024-05-09T15:21:57Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "5186190"
  uid: 2a1f9dc7-e32d-44e5-93b3-e5cf7790d95e
```

이 IAM 역할을 가장하여 접근 권한을 확인해 보겠습니다:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $ADMINS_IAM_ROLE --alias admins --user-alias admins
```

예를 들어 모든 파드를 나열할 수 있어야 합니다:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

이 IAM 역할에 대한 `aws-auth` ConfigMap 항목을 삭제하겠습니다. 편의상 `eksctl`을 사용하겠습니다:

```bash wait=10
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME --arn $ADMINS_IAM_ROLE
```

이제 이전과 동일한 명령을 시도하면 접근이 거부될 것입니다:

```bash expectError=true
$ kubectl --context admins get pod -n carts
error: You must be logged in to the server (Unauthorized)
```

클러스터 관리자가 다시 클러스터에 접근할 수 있도록 접근 항목을 추가해 보겠습니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE
```

이제 `AmazonEKSClusterAdminPolicy` 정책을 사용하는 이 주체에 대한 접근 정책을 연결할 수 있습니다:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

접근이 다시 작동하는지 테스트해 보겠습니다:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```