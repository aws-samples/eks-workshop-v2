---
title: "액세스 정책 연결하기"
sidebar_position: 13
---

`STANDARD` 유형의 액세스 엔트리에 하나 이상의 액세스 정책을 할당할 수 있습니다. Amazon EKS는 다른 유형의 액세스 엔트리에 클러스터에서 제대로 작동하는 데 필요한 권한을 자동으로 부여합니다. Amazon EKS 액세스 정책은 IAM 권한이 아닌 Kubernetes 권한을 포함합니다. 액세스 정책을 액세스 엔트리에 연결하기 전에 각 액세스 정책에 포함된 Kubernetes 권한을 잘 이해하고 있어야 합니다.

실습 설정의 일부로 `eks-workshop-read-only`라는 IAM 역할을 생성했습니다. 이 섹션에서는 읽기 전용 액세스만 허용하는 권한 세트로 이 역할에 대한 EKS 클러스터 액세스를 제공할 것입니다.

먼저 이 IAM 역할에 대한 액세스 엔트리를 생성해 보겠습니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE
```

이제 `AmazonEKSViewPolicy` 정책을 사용하는 이 주체에 대한 액세스 정책을 연결할 수 있습니다:

```bash wait=30
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=cluster
```

`--access-scope` 값으로 `type=cluster`를 사용했음을 주목하세요. 이는 주체에게 전체 클러스터에 대한 읽기 전용 액세스 권한을 부여합니다.

이제 이 역할이 가진 액세스 권한을 테스트할 수 있습니다. 먼저 읽기 전용 IAM 역할을 사용하여 클러스터와 인증하는 새로운 `kubeconfig` 항목을 설정하겠습니다. 이는 `readonly`라는 별도의 `kubectl` 컨텍스트에 매핑됩니다. 이것이 어떻게 작동하는지에 대해 [Kubernetes 문서](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)에서 자세히 알아볼 수 있습니다.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly --user-alias readonly
```

이제 `--context readonly` 인수와 함께 `kubectl` 명령을 사용하여 읽기 전용 IAM 역할로 인증할 수 있습니다. `kubectl auth whoami`를 사용하여 이를 확인하고 올바른 역할을 가장하는지 확인해 보겠습니다:

```bash
$ kubectl --context readonly auth whoami
ATTRIBUTE             VALUE
Username              arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth
UID                   aws-iam-authenticator:1234567890:AKIAIOSFODNN7EXAMPLE
Groups                [system:authenticated]
Extra: accessKeyId    [AKIAIOSFODNN7EXAMPLE]
Extra: arn            [arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth]
Extra: canonicalArn   [arn:aws:iam::1234567890:role/eks-workshop-read-only]
Extra: principalId    [AKIAIOSFODNN7EXAMPLE]
Extra: sessionName    [EKSGetTokenAuth]
```

이제 이 IAM 역할을 사용하여 클러스터의 파드에 액세스해 보겠습니다:

```bash
$ kubectl --context readonly get pod -A
```

이는 클러스터의 모든 파드를 반환해야 합니다. 하지만 읽기 이외의 작업을 수행하려고 하면 오류가 발생해야 합니다:

```bash expectError=true
$ kubectl --context readonly delete pod -n assets --all
Error from server (Forbidden): pods "assets-7c7948bfc8-wbsbr" is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot delete resource "pods" in API group "" in the namespace "assets"
```

다음으로 하나 이상의 네임스페이스로 정책을 제한하는 것을 살펴보겠습니다. `--access-scope type=namespace`를 사용하여 읽기 전용 IAM 역할에 대한 액세스 정책 연결을 업데이트합니다:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=namespace,namespaces=carts
```

이 연결은 이전의 클러스터 전체 연결을 대체하여 `carts` 네임스페이스에만 명시적으로 액세스를 허용합니다. 이를 테스트해 보겠습니다:

```bash
$ kubectl --context readonly get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

하지만 모든 네임스페이스의 파드를 가져오려고 하면 금지됩니다:

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

`readonly` 역할의 연결을 나열합니다.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:02:22.566000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

언급했듯이, 동일한 `AmazonEKSViewPolicy` 정책 ARN을 사용했기 때문에 이전의 클러스터 범위 액세스 구성을 네임스페이스 범위로 대체했습니다. 이제 `assets` 네임스페이스에 대해 다른 정책 ARN을 연결하세요.

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=assets
```

이전에 거부된 `assets` 네임스페이스의 파드 삭제 명령을 다시 실행해보세요.

```bash
$ kubectl --context readonly delete pod -n assets --all
pod "assets-7c7948bfc8-xdmnv" deleted
```

이제 두 네임스페이스 모두에 액세스할 수 있습니다. 연결된 액세스 정책을 나열하세요.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "assets"
                ]
            },
            "associatedAt": "2024-05-29T17:23:55.299000+00:00",
            "modifiedAt": "2024-05-29T17:23:55.299000+00:00"
        },
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:23:28.168000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

보시다시피 서로 다른 수준의 액세스를 제공하기 위해 둘 이상의 액세스 정책을 연결할 수 있습니다.

클러스터의 모든 파드를 나열할 때 어떤 일이 발생하는지 확인하세요.

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

액세스 범위가 `assets`와 `carts` 네임스페이스에 매핑되어 있기 때문에 여전히 전체 클러스터에 대한 액세스 권한이 없습니다.

이를 통해 사전 정의된 EKS 액세스 정책을 액세스 엔트리에 연결하여 IAM 역할에 EKS 클러스터에 대한 액세스 권한을 쉽게 제공할 수 있는 방법을 보여주었습니다.