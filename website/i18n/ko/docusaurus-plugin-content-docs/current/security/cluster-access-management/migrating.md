---
title: "aws-auth 아이덴티티 매핑에서 마이그레이션"
sidebar_position: 20
tmdTranslationSourceHash: '27e2f94a480c0774ad93f80a8b436f68'
---

이미 Amazon EKS를 사용하고 있는 고객은 클러스터에 대한 IAM 주체 액세스를 관리하기 위한 `aws-auth` ConfigMap 메커니즘에 익숙할 수 있습니다. 이 섹션에서는 이 기존 메커니즘에서 클러스터 액세스 항목을 사용하는 방식으로 항목을 마이그레이션하는 방법을 보여줍니다.

EKS 관리자 권한을 가진 그룹에 사용되는 IAM role `eks-workshop-admins`가 EKS 클러스터에 미리 구성되어 있습니다. `aws-auth` ConfigMap을 확인해 보겠습니다:

```bash
$ kubectl --context default get -n kube-system cm aws-auth -o yaml
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

이 IAM role을 가장하여 액세스 권한을 확인해 보겠습니다:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $ADMINS_IAM_ROLE --alias admins --user-alias admins
```

예를 들어 모든 Pod를 나열할 수 있어야 합니다:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

이제 이 IAM role에 대한 `aws-auth` ConfigMap 항목을 삭제해 보겠습니다. 편의를 위해 `eksctl`을 사용하겠습니다:

```bash wait=10
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME --arn $ADMINS_IAM_ROLE
```

이전과 동일한 명령을 시도하면 이제 액세스가 거부됩니다:

```bash expectError=true
$ kubectl --context admins get pod -n carts
error: You must be logged in to the server (Unauthorized)
```

클러스터 관리자가 다시 클러스터에 액세스할 수 있도록 액세스 항목을 추가해 보겠습니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE
```

다음으로, `AmazonEKSClusterAdminPolicy` 정책을 사용하여 이 주체에 대한 액세스 정책을 연결하겠습니다:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

이제 액세스가 다시 작동하는지 테스트할 수 있습니다:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

이러한 단계를 따라 `aws-auth` ConfigMap에서 더 새로운 Cluster Access Management API를 사용하는 방식으로 IAM role을 성공적으로 마이그레이션했습니다. 이는 Amazon EKS 클러스터에 대한 액세스를 관리하는 보다 간소화된 방법을 제공합니다.

