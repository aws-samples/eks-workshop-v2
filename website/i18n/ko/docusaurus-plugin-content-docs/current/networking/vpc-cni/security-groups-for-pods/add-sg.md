---
title: "Security Group 적용"
sidebar_position: 40
hide_table_of_contents: true
tmdTranslationSourceHash: '2752d62a54e6d0a42b309d5b63b025c2'
---

catalog Pod가 RDS 인스턴스에 성공적으로 연결하려면 올바른 security group을 사용해야 합니다. 이 security group을 EKS 워커 노드 자체에 적용할 수도 있지만, 이렇게 하면 클러스터의 모든 워크로드가 RDS 인스턴스에 네트워크 액세스할 수 있게 됩니다. 대신, Security Groups for Pods를 사용하여 catalog Pod가 RDS 인스턴스에 액세스할 수 있도록 구체적으로 허용하겠습니다.

RDS 데이터베이스에 대한 액세스를 허용하는 security group이 이미 설정되어 있으며, 다음과 같이 확인할 수 있습니다:

```bash
$ export CATALOG_SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$EKS_CLUSTER_NAME-catalog \
    --query "SecurityGroups[0].GroupId" --output text)
$ aws ec2 describe-security-groups \
  --group-ids $CATALOG_SG_ID | jq '.'
{
  "SecurityGroups": [
    {
      "Description": "Applied to catalog application pods",
      "GroupName": "eks-workshop-catalog",
      "IpPermissions": [
        {
          "FromPort": 8080,
          "IpProtocol": "tcp",
          "IpRanges": [
            {
              "CidrIp": "10.42.0.0/16",
              "Description": "Allow inbound HTTP API traffic"
            }
          ],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "ToPort": 8080,
          "UserIdGroupPairs": []
        }
      ],
      "OwnerId": "1234567890",
      "GroupId": "sg-037ec36e968f1f5e7",
      "IpPermissionsEgress": [
        {
          "IpProtocol": "-1",
          "IpRanges": [
            {
              "CidrIp": "0.0.0.0/0",
              "Description": "Allow all egress"
            }
          ],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "UserIdGroupPairs": []
        }
      ],
      "VpcId": "vpc-077ca8c89d111b3c1"
    }
  ]
}
```

이 security group은:

- 포트 8080에서 Pod가 제공하는 HTTP API에 대한 인바운드 트래픽을 허용합니다
- 모든 아웃바운드 트래픽을 허용합니다
- 앞서 확인한 것처럼 RDS 데이터베이스에 액세스할 수 있도록 허용됩니다

Pod가 이 security group을 사용하려면 `SecurityGroupPolicy` CRD를 사용하여 특정 Pod 집합에 어떤 security group을 매핑할지 EKS에 알려야 합니다. 다음과 같이 구성하겠습니다:

::yaml{file="manifests/modules/networking/securitygroups-for-pods/sg/policy.yaml" paths="spec.podSelector,spec.securityGroups.groupIds"}

1. `podSelector`는 `app.kubernetes.io/component: service` 레이블이 있는 Pod를 대상으로 합니다
2. 위에서 내보낸 `CATALOG_SG_ID` 환경 변수에는 일치하는 Pod에 매핑될 security group ID가 포함되어 있습니다

이를 클러스터에 적용한 다음 catalog Pod를 다시 재시작합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/securitygroups-for-pods/sg \
  | envsubst | kubectl apply -f-
namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
configmap/catalog-env-97g7bft95f unchanged
configmap/catalog-sg-env-54k244c6t7 created
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
service/ui-nlb unchanged
deployment.apps/catalog unchanged
statefulset.apps/catalog-mysql unchanged
securitygrouppolicy.vpcresources.k8s.aws/catalog-rds-access created
$ kubectl delete pod -n catalog -l app.kubernetes.io/component=service
pod "catalog-6ccc6b5575-glfxc" deleted
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
deployment "catalog" successfully rolled out
```

이번에는 catalog Pod가 시작되고 롤아웃이 성공합니다. 로그를 확인하여 RDS 데이터베이스에 연결되고 있는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog logs deployment/catalog
Using mysql database eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
Running database migration...
Database migration complete
```

