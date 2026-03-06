---
title: "Kubernetes RBAC와 통합"
sidebar_position: 14
tmdTranslationSourceHash: 0ac86d001c5ec50d2f31c060afddc908
---

앞서 언급했듯이, 클러스터 액세스 관리 제어와 관련 API는 Amazon EKS의 기존 RBAC authorizer를 대체하지 않습니다. 오히려 Amazon EKS 액세스 엔트리는 RBAC authorizer와 결합하여 AWS IAM principal에 클러스터 액세스를 부여하면서 Kubernetes RBAC를 활용하여 원하는 권한을 적용할 수 있습니다.

이 실습 섹션에서는 Kubernetes 그룹을 사용하여 세밀한 권한으로 액세스 엔트리를 구성하는 방법을 보여드리겠습니다. 이는 사전 정의된 액세스 정책이 너무 광범위할 때 유용합니다. 실습 설정의 일부로 `eks-workshop-carts-team`이라는 IAM role을 생성했습니다. 이 시나리오에서는 **carts** 서비스에서만 작업하는 팀에게 `carts` 네임스페이스의 모든 리소스를 볼 수 있지만 Pod를 삭제할 수도 있는 권한을 제공하는 방법을 보여드리겠습니다.

먼저, 필요한 권한을 모델링하는 Kubernetes 객체를 생성하겠습니다. 이 Role은 위에서 설명한 권한을 제공합니다:

::yaml{file="manifests/modules/security/cam/rbac/role.yaml" paths="metadata.namespace,rules.0,rules.1"}

1. Role 권한을 `carts` 네임스페이스에만 적용되도록 제한합니다
2. 이 규칙은 모든 리소스 `resources: ["*"]`에 대한 읽기 전용 작업 `verbs: ["get", "list", "watch"]`을 허용합니다
3. 이 규칙은 Pod에만 `resources: ["pods"]` 특정하여 삭제 작업 `verbs: ["delete"]`을 허용합니다

그리고 이 `RoleBinding`은 Role을 `carts-team`이라는 Group에 매핑합니다:

::yaml{file="manifests/modules/security/cam/rbac/rolebinding.yaml" paths="roleRef,subjects.0"}

1. `roleRef`는 앞서 생성한 `carts-team-role` Role을 참조합니다
2. `subjects`는 `carts-team`이라는 Group이 Role과 연결된 권한을 얻게 됨을 지정합니다

이 매니페스트를 적용해보겠습니다:

```bash
$ kubectl --context default apply -k ~/environment/eks-workshop/modules/security/cam/rbac
```

이제 carts 팀의 IAM role을 `carts-team` Kubernetes RBAC 그룹에 매핑하는 액세스 엔트리를 생성하겠습니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $CARTS_TEAM_IAM_ROLE \
  --kubernetes-groups carts-team
```

이제 이 role이 가진 액세스를 테스트할 수 있습니다. carts 팀의 IAM role을 사용하여 클러스터에 인증하는 새 `kubeconfig` 엔트리를 `carts-team` 컨텍스트로 설정하겠습니다:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $CARTS_TEAM_IAM_ROLE --alias carts-team --user-alias carts-team
```

이제 `--context carts-team`을 사용하여 carts 팀의 IAM role로 `carts` 네임스페이스의 Pod에 액세스해보겠습니다:

```bash
$ kubectl --context carts-team get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-hp7x8          1/1     Running   0          3m27s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

네임스페이스에서 Pod를 삭제할 수도 있어야 합니다:

```bash
$ kubectl --context carts-team delete pod --all -n carts
pod "carts-6d4478747c-hp7x8" deleted
pod "carts-dynamodb-d9f9f48b-k5v99" deleted
```

하지만 `Deployment`와 같은 다른 리소스를 삭제하려고 하면 거부됩니다:

```bash expectError=true
$ kubectl --context carts-team delete deployment --all -n carts
Error from server (Forbidden): deployments.apps is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "deployments" in API group "apps" in the namespace "carts"
```

그리고 다른 네임스페이스의 Pod에 액세스하려고 하면 역시 거부됩니다:

```bash expectError=true
$ kubectl --context carts-team get pod -n catalog
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "pods" in API group "" in the namespace "catalog"
```

이것은 Kubernetes RBAC 그룹을 액세스 엔트리에 연결하여 IAM role에 대한 EKS 클러스터의 세밀한 권한을 제공하는 방법을 보여주었습니다.

