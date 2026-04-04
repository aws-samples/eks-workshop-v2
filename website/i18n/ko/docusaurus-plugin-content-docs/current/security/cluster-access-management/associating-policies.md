---
title: "액세스 정책 연결"
sidebar_position: 13
tmdTranslationSourceHash: ba70c54bd69ec0917ba9964b493675fa
---

`STANDARD` 타입의 액세스 엔트리에 하나 이상의 액세스 정책을 할당할 수 있습니다. Amazon EKS는 다른 타입의 액세스 엔트리에 대해서는 클러스터에서 제대로 작동하는 데 필요한 권한을 자동으로 부여합니다. Amazon EKS 액세스 정책에는 IAM 권한이 아닌 Kubernetes 권한이 포함됩니다. 액세스 정책을 액세스 엔트리에 연결하기 전에, 각 액세스 정책에 포함된 Kubernetes 권한을 숙지하고 있는지 확인하세요.

실습 설정의 일환으로 `eks-workshop-read-only`라는 IAM 역할을 생성했습니다. 이 섹션에서는 이 IAM 역할에 대해 읽기 전용 액세스만 허용하는 권한 집합으로 EKS 클러스터에 대한 액세스를 제공하겠습니다.

먼저 이 IAM 역할에 대한 액세스 엔트리를 생성해 보겠습니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE
```

이제 `AmazonEKSViewPolicy` 정책을 사용하는 이 프린시펄에 대한 액세스 정책을 연결할 수 있습니다:

```bash wait=30
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=cluster
```

`--access-scope` 값으로 `type=cluster`를 사용했다는 점에 주목하세요. 이는 프린시펄에게 전체 클러스터에 대한 읽기 전용 액세스를 제공합니다.

이제 이 역할이 가진 액세스를 테스트할 수 있습니다. 먼저 읽기 전용 IAM 역할을 사용하여 클러스터에 인증하는 새 `kubeconfig` 엔트리를 설정하겠습니다. 이는 `readonly`라는 별도의 `kubectl` 컨텍스트에 매핑됩니다. 이것이 어떻게 작동하는지에 대한 자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)에서 확인할 수 있습니다.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly --user-alias readonly
```

이제 `--context readonly` 인수와 함께 `kubectl` 명령을 사용하여 읽기 전용 IAM 역할로 인증할 수 있습니다. `kubectl auth whoami`를 사용하여 이를 확인하고 올바른 역할을 가장할 것인지 확인해 보겠습니다:

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

이제 이 IAM 역할을 사용하여 클러스터의 Pod에 액세스해 보겠습니다:

```bash
$ kubectl --context readonly get pod -A
```

이 명령은 클러스터의 모든 Pod를 반환해야 합니다. 그러나 읽기 이외의 작업을 수행하려고 하면 오류가 발생해야 합니다:

```bash expectError=true
$ kubectl --context readonly delete pod -n ui --all
Error from server (Forbidden): pods "ui-7c7948bfc8-wbsbr" is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot delete resource "pods" in API group "" in the namespace "ui"
```

다음으로 정책을 하나 이상의 네임스페이스로 제한하는 것을 살펴볼 수 있습니다. `--access-scope type=namespace`를 사용하여 읽기 전용 IAM 역할에 대한 액세스 정책 연결을 업데이트해 보겠습니다:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=namespace,namespaces=carts
```

이 연결은 `carts` 네임스페이스에만 명시적으로 액세스를 허용하며, 이전의 클러스터 전체 연결을 대체합니다. 이를 테스트해 보겠습니다:

```bash
$ kubectl --context readonly get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

하지만 모든 네임스페이스에서 Pod를 가져오려고 하면 금지됩니다:

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

`readonly` 역할의 연결을 나열해 보겠습니다:

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

언급한 바와 같이, 동일한 `AmazonEKSViewPolicy` 정책 ARN을 사용했기 때문에 이전의 클러스터 범위 액세스 구성을 네임스페이스 범위로 대체했습니다. 이제 `ui` 네임스페이스로 범위가 지정된 다른 정책 ARN을 연결해 보겠습니다:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=ui
```

이전에 액세스가 거부되었던 `ui` 네임스페이스의 Pod를 삭제하는 명령을 실행해 보겠습니다:

```bash
$ kubectl --context readonly delete pod -n ui --all
pod "ui-7c7948bfc8-xdmnv" deleted
```

이제 두 네임스페이스 모두에 액세스할 수 있습니다. 연결된 액세스 정책을 나열해 보겠습니다:

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "ui"
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

보시다시피, 여러 액세스 정책을 연결하여 서로 다른 수준의 액세스를 제공할 수 있습니다.

클러스터의 모든 Pod를 나열하려고 하면 어떻게 되는지 확인해 보겠습니다:

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

전체 클러스터에 대한 액세스 권한이 여전히 없으며, 액세스 범위가 `ui`와 `carts` 네임스페이스에만 매핑되어 있기 때문에 예상되는 결과입니다.

이를 통해 사전 정의된 EKS 액세스 정책을 액세스 엔트리에 연결하여 IAM 역할에 EKS 클러스터에 대한 액세스를 쉽게 제공하는 방법을 시연했습니다.

