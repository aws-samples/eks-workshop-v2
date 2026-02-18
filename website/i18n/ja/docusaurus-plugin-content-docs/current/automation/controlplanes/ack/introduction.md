---
title: "はじめに"
sidebar_position: 3
tmdTranslationSourceHash: c50b1ee6030afba367dfa41a583f4641
---

各ACKサービスコントローラーは、個々のACKサービスコントローラーに対応するパブリックリポジトリで公開される別々のコンテナイメージにパッケージ化されています。プロビジョニングしたいAWSサービスごとに、対応するコントローラーのリソースをAmazon EKSクラスターにインストールする必要があります。ACKのHelm chartと公式コンテナイメージは[こちら](https://gallery.ecr.aws/aws-controllers-k8s)で入手できます。

このセクションでは、Amazon DynamoDB ACKを使用するため、まずHelmチャートを使用してそのACKコントローラーをインストールする必要があります：

```bash wait=60
$ aws ecr-public get-login-password --region us-east-1 | \
  helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install ack-dynamodb  \
  oci://public.ecr.aws/aws-controllers-k8s/dynamodb-chart \
  --version=${DYNAMO_ACK_VERSION} \
  --namespace ack-system --create-namespace \
  --set "aws.region=${AWS_REGION}" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$ACK_IAM_ROLE" \
  --wait
```

コントローラーは`ack-system`名前空間内のデプロイメントとして実行されます：

```bash
$ kubectl get deployment -n ack-system
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
ack-dynamodb-dynamodb-chart   1/1     1            1           13s
```
