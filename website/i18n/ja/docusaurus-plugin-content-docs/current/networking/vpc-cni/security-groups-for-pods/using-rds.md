---
title: "Amazon RDSの使用"
sidebar_position: 20
tmdTranslationSourceHash: 27caca5707cf17c38fa3f60553a150be
---

私たちのアカウントにRDSデータベースが作成されています。後で使用するためにそのエンドポイントとパスワードを取得しましょう：

```bash
$ export CATALOG_RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $EKS_CLUSTER_NAME-catalog | jq -r '.DBInstances[0].Endpoint.Address')
$ echo $CATALOG_RDS_ENDPOINT
eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com
$ export CATALOG_RDS_PASSWORD=$(aws ssm get-parameter --name $EKS_CLUSTER_NAME-catalog-db --region $AWS_REGION --query "Parameter.Value" --output text --with-decryption)
```

このプロセスの最初のステップは、すでに作成されているAmazon RDSデータベースを使用するようにcatalogサービスを再構成することです。アプリケーションは設定のほとんどをConfigMapから読み込みます。確認してみましょう：

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

以下のkustomizationはConfigMapを上書きし、MySQLエンドポイントを変更して、アプリケーションが環境変数`CATALOG_RDS_ENDPOINT`から取得している、すでに作成されているAmazon RDSデータベースに接続するようにします：

```kustomization
modules/networking/securitygroups-for-pods/rds/kustomization.yaml
ConfigMap/catalog
```

RDSデータベースを使用するために、この変更を適用しましょう：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/securitygroups-for-pods/rds \
  | envsubst | kubectl apply -f-
```

ConfigMapが新しい値で更新されたことを確認しましょう：

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

これで、新しいConfigMapの内容を取得するためにcatalogポッドをリサイクルする必要があります：

```bash expectError=true
$ kubectl delete pod -n catalog -l app.kubernetes.io/component=service
pod "catalog-788bb5d488-9p6cj" deleted
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
Waiting for deployment "catalog" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

エラーが発生しました - catalogポッドが時間内に再起動できなかったようです。何が問題なのでしょうか？ポッドのログをチェックして何が起きたか確認しましょう：

```bash
$ kubectl -n catalog logs deployment/catalog
Using mysql database eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306

2025/05/06 05:52:02 /appsrc/repository/repository.go:32
[error] failed to initialize database, got error dial tcp 10.42.179.30:3306: i/o timeout
panic: failed to connect database
```

ポッドがRDSデータベースに接続できません。RDSデータベースに適用されているEC2セキュリティグループを次のように確認できます：

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

AWSコンソールからもRDSインスタンスのセキュリティグループを確認できます：

<ConsoleButton url="https://console.aws.amazon.com/rds/home#database:id=eks-workshop-catalog;is-cluster=false" service="rds" label="RDSコンソールを開く"/>

このセキュリティグループは、特定のセキュリティグループ（上記の例では`sg-037ec36e968f1f5e7`）を持つソースからのトラフィックのみが、ポート`3306`でRDSデータベースにアクセスすることを許可しています。
