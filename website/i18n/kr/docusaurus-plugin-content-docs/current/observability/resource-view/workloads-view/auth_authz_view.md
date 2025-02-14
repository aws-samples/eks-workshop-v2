---
title: "인증 및 권한 부여"
sidebar_position: 50
---

**<i>인증</i>** 탭을 클릭하여 <i>ServiceAccounts</i> 섹션으로 들어가면 네임스페이스별로 Kubernetes 서비스 계정 리소스를 볼 수 있습니다.

:::info
추가 예제는 [보안](../../../security/) 모듈을 확인하세요.
:::
[ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)는 Pod에서 실행되는 프로세스에 대한 ID를 제공합니다. Pod를 생성할 때 서비스 계정을 지정하지 않으면 동일한 네임스페이스의 기본 서비스 계정이 자동으로 할당됩니다.

![Insights](/img/resource-view/auth-resources.jpg)

특정 <i>서비스 계정</i>에 대한 추가 세부 정보를 보려면 네임스페이스로 들어가서 보고 싶은 서비스 계정을 클릭하여 <i>레이블</i>, <i>주석</i>, <i>이벤트</i>와 같은 추가 정보를 확인할 수 있습니다. 아래는 <i>catalog</i> 서비스 계정에 대한 상세 보기입니다.

EKS에서는 요청이 <i>권한 부여</i>(접근 권한 부여)되기 전에 **<i>인증</i>**(로그인)이 되어야 합니다. Kubernetes는 REST API 요청에 공통적인 속성을 기대합니다. 이는 EKS 권한 부여가 접근 제어를 위해 [AWS Identity and Access Management](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html)와 함께 작동한다는 것을 의미합니다.

이 실습에서는 Kubernetes **역할 기반 접근 제어(RBAC)** 리소스인 ClusterRoles, Roles, ClusterRoleBindings 및 RoleBindings를 살펴볼 것입니다. RBAC는 EKS 클러스터 사용자에게 매핑된 IAM 역할에 따라 EKS 클러스터와 그 객체에 대한 제한된 최소 권한 접근을 제공하는 프로세스입니다. 다음 다이어그램은 사용자 또는 서비스 계정이 Kubernetes 클라이언트 및 API를 통해 EKS 클러스터의 객체에 접근하려고 할 때 접근 제어가 어떻게 흐르는지를 보여줍니다.

:::info
추가 예제는 [보안](../../../security/) 모듈을 확인하세요.
:::

![Insights](/img/resource-view/autz-index.jpg)

**[Role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)**은 사용자에게 적용될 권한 집합을 정의합니다. 역할 기반 접근 제어(RBAC)는 조직 내 개별 사용자의 역할을 기반으로 컴퓨터 또는 네트워크 리소스에 대한 접근을 규제하는 방법입니다. Role은 항상 특정 네임스페이스 내에서 권한을 설정하며, Role을 생성할 때 해당 Role이 속한 네임스페이스를 지정해야 합니다.

**_리소스 유형_** - **_권한 부여_** 섹션에서 클러스터의 **_ClusterRoles_**와 **_Roles_** 리소스를 네임스페이스별로 볼 수 있습니다.

![Insights](/img/resource-view/autz-role.jpg)

**_cluster-autoscaler-aws-cluster-autoscaler_** 역할을 클릭하여 해당 **_역할_**에 대한 자세한 정보를 볼 수 있습니다. 아래 스크린샷은 **_kube-system_** 네임스페이스에 생성된 **_cluster-autoscaler-aws-cluster-autoscaler_** 역할을 보여주며, 이 역할은 **_configmaps_** 리소스에 대해 **_삭제_**, **_조회_**, **_업데이트_** 권한을 가지고 있습니다.

![Insights](/img/resource-view/autz-role-detail.jpg)

**[ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)**는 네임스페이스가 아닌 클러스터 범위로 지정된 규칙 집합으로, 이는 **_Role_**과 다릅니다. **_ClusterRoles_**는 추가적이며, "거부" 규칙을 설정할 수 없습니다. 일반적으로 **_ClusterRoles_**를 사용하여 클러스터 전체 권한을 정의합니다.

**[Role binding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)**은 사용자 또는 사용자 집합에 역할 권한을 부여합니다. Rolebindings는 생성 시 특정 네임스페이스에 할당됩니다. Rolebinding 리소스는 주체(사용자, 그룹 또는 서비스 계정) 목록과 부여되는 역할에 대한 참조를 포함합니다. **_RoleBinding_**은 pods, replicasets, jobs, deployments와 같은 특정 네임스페이스 내의 권한을 부여합니다. 반면에 **_ClusterRoleBinding_**은 노드와 같은 클러스터 범위의 리소스에 대한 권한을 부여합니다.

**[ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)**은 **_ClusterRoles_**를 사용자 집합에 연결합니다. 이들은 클러스터 범위로 지정되며, **_Roles_**와 **_RoleBindings_**처럼 네임스페이스에 바인딩되지 않습니다.

![Insights](/img/resource-view/authz-crolebinding.jpg)