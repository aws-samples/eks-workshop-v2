---
title: "보안 그룹 적용하기"
sidebar_position: 40
hide_table_of_contents: true
---

카탈로그 Pod가 RDS 인스턴스에 성공적으로 연결하기 위해서는 올바른 보안 그룹을 사용해야 합니다. 이 보안 그룹을 EKS 워커 노드 자체에 적용할 수 있지만, 이는 클러스터의 모든 워크로드가 RDS 인스턴스에 대한 네트워크 액세스 권한을 갖게 되는 결과를 초래합니다. 대신 Pod용 보안 그룹을 적용하여 카탈로그 Pod가 RDS 인스턴스에 접근할 수 있도록 특별히 허용할 것입니다.

RDS 데이터베이스에 대한 접근을 허용하는 보안 그룹이 이미 설정되어 있으며, 다음과 같이 확인할 수 있습니다:

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

이 보안 그룹은:

- Pod가 제공하는 HTTP API에 대한 8080 포트의 인바운드 트래픽을 허용합니다
- 모든 이그레스 트래픽을 허용합니다
- 앞서 보았듯이 RDS 데이터베이스에 접근할 수 있도록 허용됩니다

Pod가 이 보안 그룹을 사용하기 위해서는 `SecurityGroupPolicy` CRD를 사용하여 EKS에 어떤 보안 그룹이 특정 Pod 세트에 매핑되어야 하는지 알려줘야 합니다. 다음과 같이 구성할 것입니다:

```file
manifests/modules/networking/securitygroups-for-pods/sg/policy.yaml
```

이것을 클러스터에 적용한 다음 카탈로그 Pod를 다시 한 번 재시작합니다:

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

이번에는 카탈로그 Pod가 시작되고 롤아웃이 성공할 것입니다. 로그를 확인하여 RDS 데이터베이스에 연결되는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog logs deployment/catalog | grep Connect
2022/12/20 20:52:10 Connecting to catalog_user:xxxxxxxxxx@tcp(eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306)/catalog?timeout=5s
2022/12/20 20:52:10 Connected
2022/12/20 20:52:10 Connecting to catalog_user:xxxxxxxxxx@tcp(eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306)/catalog?timeout=5s
2022/12/20 20:52:10 Connected
```