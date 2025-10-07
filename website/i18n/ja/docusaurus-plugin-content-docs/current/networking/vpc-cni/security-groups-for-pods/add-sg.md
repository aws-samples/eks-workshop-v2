---
title: "セキュリティグループの適用"
sidebar_position: 40
hide_table_of_contents: true
kiteTranslationSourceHash: 2752d62a54e6d0a42b309d5b63b025c2
---

カタログPodがRDSインスタンスに正常に接続するためには、正しいセキュリティグループを使用する必要があります。このセキュリティグループはEKSワーカーノード自体に適用することもできますが、これによりクラスター内のどのワークロードでもRDSインスタンスへのネットワークアクセスが可能になってしまいます。代わりに、Podのセキュリティグループを使用して、特定のカタログPodのみがRDSインスタンスにアクセスできるようにします。

RDSデータベースへのアクセスを許可するセキュリティグループは既にセットアップされており、次のように表示できます：

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

このセキュリティグループは：

- ポート8080でPodが提供するHTTP APIへのインバウンドトラフィックを許可
- すべてのエグレストラフィックを許可
- 先ほど見たように、RDSデータベースへのアクセスが許可される

Podがこのセキュリティグループを使用するためには、`SecurityGroupPolicy` CRDを使用してEKSに特定のセキュリティグループを特定のPodセットにマッピングするよう指示する必要があります。設定内容は次のとおりです：

::yaml{file="manifests/modules/networking/securitygroups-for-pods/sg/policy.yaml" paths="spec.podSelector,spec.securityGroups.groupIds"}

1. `podSelector`は`app.kubernetes.io/component: service`というラベルを持つPodをターゲットにします
2. 上記でエクスポートした`CATALOG_SG_ID`環境変数には、一致するPodにマッピングされるセキュリティグループIDが含まれています

これをクラスターに適用し、カタログPodを再度リサイクルします：

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

今回はカタログPodが起動し、ロールアウトは成功します。ログを確認してRDSデータベースに接続していることを確認できます：

```bash
$ kubectl -n catalog logs deployment/catalog
Using mysql database eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
Running database migration...
Database migration complete
```
