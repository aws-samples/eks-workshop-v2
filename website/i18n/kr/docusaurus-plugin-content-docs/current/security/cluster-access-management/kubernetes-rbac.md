---
title: "Kubernetes RBAC 통합"
sidebar_position: 14
---

앞서 언급했듯이, 클러스터 접근 관리 제어와 관련 API는 Amazon EKS의 기존 RBAC 인가자를 대체하지 않습니다. 대신, Amazon EKS 접근 항목은 RBAC 인가자와 결합하여 AWS IAM 주체에게 클러스터 접근 권한을 부여하면서 Kubernetes RBAC을 통해 원하는 권한을 적용할 수 있습니다.

이 실습 섹션에서는 Kubernetes 그룹을 사용하여 세분화된 권한으로 접근 항목을 구성하는 방법을 보여드리겠습니다. 이는 사전 정의된 접근 정책이 너무 광범위한 권한을 부여할 때 유용합니다. 실습 설정의 일환으로 `eks-workshop-carts-team`이라는 IAM 역할을 생성했습니다. 이 시나리오에서는 해당 역할을 사용하여 **carts** 서비스만 작업하는 팀에게 `carts` 네임스페이스의 모든 리소스를 볼 수 있는 권한과 파드를 삭제할 수 있는 권한을 제공하는 방법을 보여드리겠습니다.

먼저 필요한 권한을 모델링하는 Kubernetes 객체를 생성해 보겠습니다. 이 `Role`은 위에서 설명한 권한을 제공합니다:

```file
manifests/modules/security/cam/rbac/role.yaml
```

그리고 이 `RoleBinding`은 역할을 `carts-team`이라는 그룹에 매핑합니다:

```file
manifests/modules/security/cam/rbac/rolebinding.yaml
```

이 매니페스트들을 적용합니다:

```bash
$ kubectl --context default apply -k ~/environment/eks-workshop/modules/security/cam/rbac
```

마지막으로 carts 팀의 IAM 역할을 `carts-team` Kubernetes RBAC 그룹에 매핑하는 접근 항목을 생성합니다:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $CARTS_TEAM_IAM_ROLE \
  --kubernetes-groups carts-team
```

이제 이 역할이 가진 접근 권한을 테스트할 수 있습니다. carts 팀의 IAM 역할을 사용하여 클러스터에 인증하는 새로운 `kubeconfig` 항목을 `carts-team` 컨텍스트로 설정합니다:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $CARTS_TEAM_IAM_ROLE --alias carts-team --user-alias carts-team
```

이제 carts 팀의 IAM 역할을 사용하여 `--context carts-team`으로 `carts` 네임스페이스의 파드에 접근해 보겠습니다:

```bash
$ kubectl --context carts-team get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-hp7x8          1/1     Running   0          3m27s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

네임스페이스의 파드를 삭제할 수도 있어야 합니다:

```bash
$ kubectl --context carts-team delete pod --all -n carts
pod "carts-6d4478747c-hp7x8" deleted
pod "carts-dynamodb-d9f9f48b-k5v99" deleted
```

하지만 `Deployment`와 같은 다른 리소스를 삭제하려고 하면 금지됩니다:

```bash expectError=true
$ kubectl --context carts-team delete deployment --all -n carts
Error from server (Forbidden): deployments.apps is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "deployments" in API group "apps" in the namespace "carts"
```

그리고 다른 네임스페이스의 파드에 접근하려고 해도 금지됩니다:

```bash expectError=true
$ kubectl --context carts-team get pod -n catalog
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "pods" in API group "" in the namespace "catalog"
```

이를 통해 Kubernetes RBAC 그룹을 접근 항목과 연결하여 IAM 역할에 EKS 클러스터에 대한 세분화된 권한을 쉽게 제공할 수 있음을 보여주었습니다.