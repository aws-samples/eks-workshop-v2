---
title: "Amazon RDS 사용하기"
sidebar_position: 20
tmdTranslationSourceHash: '27caca5707cf17c38fa3f60553a150be'
---

RDS 데이터베이스가 우리 계정에 생성되었습니다. 나중에 사용할 엔드포인트와 비밀번호를 가져오겠습니다:

```bash
$ export CATALOG_RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $EKS_CLUSTER_NAME-catalog | jq -r '.DBInstances[0].Endpoint.Address')
$ echo $CATALOG_RDS_ENDPOINT
eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com
$ export CATALOG_RDS_PASSWORD=$(aws ssm get-parameter --name $EKS_CLUSTER_NAME-catalog-db --region $AWS_REGION --query "Parameter.Value" --output text --with-decryption)
```

이 과정의 첫 번째 단계는 이미 생성된 Amazon RDS 데이터베이스를 사용하도록 catalog 서비스를 재구성하는 것입니다. 애플리케이션은 ConfigMap에서 대부분의 구성을 로드합니다. 한번 살펴보겠습니다:

```bash
$ kubectl -n catalog get -o yaml cm catalog
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: catalog
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: catalog-mysql:3306
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: mysql
kind: ConfigMap
metadata:
  name: catalog
  namespace: catalog
```

다음 kustomization은 ConfigMap을 덮어쓰며, MySQL 엔드포인트를 변경하여 애플리케이션이 이미 생성된 Amazon RDS 데이터베이스에 연결하도록 합니다. 이는 환경 변수 `CATALOG_RDS_ENDPOINT`에서 가져옵니다:

```kustomization
modules/networking/securitygroups-for-pods/rds/kustomization.yaml
ConfigMap/catalog
```

RDS 데이터베이스를 사용하도록 이 변경사항을 적용해 보겠습니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/securitygroups-for-pods/rds \
  | envsubst | kubectl apply -f-
```

ConfigMap이 새로운 값으로 업데이트되었는지 확인합니다:

```bash
$ kubectl get -n catalog cm catalog -o yaml
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: catalog
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: mysql
kind: ConfigMap
metadata:
  labels:
    app: catalog
  name: catalog
  namespace: catalog
```

이제 새로운 ConfigMap 내용을 적용하기 위해 catalog Pod를 재시작해야 합니다:

```bash expectError=true
$ kubectl delete pod -n catalog -l app.kubernetes.io/component=service
pod "catalog-788bb5d488-9p6cj" deleted
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
Waiting for deployment "catalog" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

오류가 발생했습니다 - catalog Pod가 제시간에 재시작되지 못한 것 같습니다. 무엇이 잘못되었을까요? Pod 로그를 확인하여 무슨 일이 일어났는지 살펴보겠습니다:

```bash
$ kubectl -n catalog logs deployment/catalog
Using mysql database eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306

2025/05/06 05:52:02 /appsrc/repository/repository.go:32
[error] failed to initialize database, got error dial tcp 10.42.179.30:3306: i/o timeout
panic: failed to connect database
```

Pod가 RDS 데이터베이스에 연결할 수 없습니다. RDS 데이터베이스에 적용된 EC2 Security Group을 다음과 같이 확인할 수 있습니다:

```bash
$ aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$VPC_ID Name=tag:Name,Values=$EKS_CLUSTER_NAME-catalog-rds | jq '.'
{
  "SecurityGroups": [
    {
      "Description": "Catalog RDS security group",
      "GroupName": "eks-workshop-catalog-rds-20221220135004125100000005",
      "IpPermissions": [
        {
          "FromPort": 3306,
          "IpProtocol": "tcp",
          "IpRanges": [],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "ToPort": 3306,
          "UserIdGroupPairs": [
            {
              "Description": "MySQL access from within VPC",
              "GroupId": "sg-037ec36e968f1f5e7",
              "UserId": "1234567890"
            }
          ]
        }
      ],
      "OwnerId": "1234567890",
      "GroupId": "sg-0b47cdc59485262ea",
      "IpPermissionsEgress": [],
      "Tags": [
        {
          "Key": "Name",
          "Value": "eks-workshop-catalog-rds"
        }
      ],
      "VpcId": "vpc-077ca8c89d111b3c1"
    }
  ]
}
```

AWS 콘솔을 통해 RDS 인스턴스의 보안 그룹을 확인할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/rds/home#database:id=eks-workshop-catalog;is-cluster=false" service="rds" label="RDS 콘솔 열기"/>

이 보안 그룹은 특정 보안 그룹을 가진 소스에서 오는 경우에만 포트 `3306`으로 RDS 데이터베이스에 액세스하는 트래픽을 허용합니다. 위의 예시에서는 `sg-037ec36e968f1f5e7`입니다.

