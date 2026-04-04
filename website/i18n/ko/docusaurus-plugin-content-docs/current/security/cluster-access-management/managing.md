---
title: "클러스터 액세스 관리"
sidebar_position: 12
tmdTranslationSourceHash: '47ef58479d59d40fc0b2c0f1c8e64c12'
---

이제 Cluster Access Management API에 대한 기본적인 이해가 되었으니, 실습을 시작해 보겠습니다. 먼저, Cluster Access Management API가 제공되기 전에는 Amazon EKS가 클러스터에 인증하고 액세스를 제공하기 위해 `aws-auth` ConfigMap에 의존했다는 것을 알아야 합니다. 이제 Amazon EKS는 세 가지 다른 인증 모드를 제공합니다:

1. `CONFIG_MAP`: `aws-auth` ConfigMap만 사용합니다 (향후 지원 중단 예정)
2. `API_AND_CONFIG_MAP`: EKS 액세스 엔트리 API와 `aws-auth` ConfigMap 모두에서 인증된 IAM 주체를 가져오며, 액세스 엔트리를 우선시합니다
3. `API`: EKS 액세스 엔트리 API에만 의존합니다 (권장 방법)

:::note
클러스터 구성을 `CONFIG_MAP`에서 `API_AND_CONFIG_MAP`으로, 그리고 `API_AND_CONFIG_MAP`에서 `API`로 업데이트할 수 있지만, 반대 방향으로는 불가능합니다. 이는 단방향 작업입니다 - Cluster Access Management API 사용으로 전환하면 `aws-auth` ConfigMap 인증에만 의존하는 방식으로 되돌릴 수 없습니다.
:::

`awscli`를 사용하여 클러스터가 어떤 인증 방법으로 구성되어 있는지 확인해 보겠습니다:

```bash
$ aws eks describe-cluster --name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
{
  "authenticationMode": "API_AND_CONFIG_MAP"
}
```

클러스터가 이미 API를 인증 옵션 중 하나로 사용하고 있으므로, EKS는 이미 몇 가지 기본 액세스 엔트리를 클러스터에 매핑했습니다. 확인해 보겠습니다:

```bash
$ aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
{
    "accessEntries": [
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-TesterCodeBuildRoleC9232875-RyhCKIXckZri"
    ]
}
```

이러한 액세스 엔트리는 인증 모드가 `API_AND_CONFIG_MAP` 또는 `API`로 설정될 때 자동으로 생성되어 클러스터 생성자 엔티티와 클러스터에 속한 Managed Node Group에 대한 액세스를 부여합니다.

클러스터 생성자는 AWS Console, `awscli`, eksctl 또는 AWS CloudFormation이나 Terraform과 같은 Infrastructure-as-Code (IaC) 도구를 통해 실제로 클러스터를 생성한 엔티티입니다. 이 ID는 생성 시 클러스터에 자동으로 매핑되며, 인증 방법이 `CONFIG_MAP`으로만 제한되었던 과거에는 표시되지 않았습니다. 이제 Cluster Access Management API를 사용하면 이 ID 매핑 생성을 선택하지 않거나 클러스터 배포 후에도 제거할 수 있습니다.

이러한 액세스 엔트리를 설명하여 더 많은 정보를 확인해 보겠습니다:

```bash
$ NODE_ROLE=$(aws eks list-access-entries --cluster $EKS_CLUSTER_NAME --output text | awk '/NodeInstanceRole/ {print $2}')
$ aws eks describe-access-entry --cluster $EKS_CLUSTER_NAME --principal-arn $NODE_ROLE
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "kubernetesGroups": [
            "system:nodes"
        ],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr/dcc7957b-b333-5c6b-f487-f7538085d799",
        "createdAt": "2024-04-29T17:46:47.836000+00:00",
        "modifiedAt": "2024-04-29T17:46:47.836000+00:00",
        "tags": {},
        "username": "system:node:{{EC2PrivateDNSName}}",
        "type": "EC2_LINUX"
    }
}
```

