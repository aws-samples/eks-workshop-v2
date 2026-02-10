---
title: Fargate の有効化
sidebar_position: 10
tmdTranslationSourceHash: 14271fb060885fe2bc8ef31b0d6211b0
---

クラスター内の Fargate で Pod をスケジュールする前に、起動時に Fargate を使用する Pod を指定する Fargate プロファイルを少なくとも 1 つ定義する必要があります。

管理者として、Fargate プロファイルを使用して、どの Pod が Fargate で実行されるかをプロファイルのセレクターを通じて宣言できます。各プロファイルには最大 5 つのセレクターを追加できます。各セレクターには名前空間とオプションのラベルが含まれます。すべてのセレクターに名前空間を定義する必要があります。ラベルフィールドは複数のオプションのキーと値のペアで構成されています。セレクターに一致する Pod は Fargate でスケジュールされます。Pod は名前空間とセレクターで指定されたラベルを使用してマッチングされます。ラベルなしで名前空間セレクターが定義されている場合、Amazon EKS はその名前空間で実行されるすべての Pod をプロファイルを使用して Fargate でスケジュールしようとします。スケジュールされる Pod が Fargate プロファイルのセレクターのいずれかに一致する場合、その Pod は Fargate でスケジュールされます。

Pod が複数の Fargate プロファイルに一致する場合、Pod に次の Kubernetes ラベルを追加することで、Pod が使用するプロファイルを指定できます：`eks.amazonaws.com/fargate-profile: my-fargate-profile`。Pod がそのプロファイル内のセレクターに一致している必要があり、Fargate 上でスケジュールされます。Kubernetes のアフィニティ/アンチアフィニティルールは Amazon EKS Fargate Pod には適用されず、必要ありません。

まず、EKS クラスターに Fargate プロファイルを追加しましょう。以下のコマンドは、次の特性を持つ `checkout-profile` という名前の Fargate プロファイルを作成します：

1. `checkout` 名前空間内で、ラベル `fargate: yes` を持つ Pod をターゲットにする
2. Pod を VPC のプライベートサブネットに配置する
3. IAM ロールを Fargate インフラストラクチャに適用して、ECR からイメージを取得したり、CloudWatch にログを書き込んだりできるようにする

次のコマンドはプロファイルを作成します。これには数分かかります：

```bash timeout=600
$ aws eks create-fargate-profile \
    --cluster-name ${EKS_CLUSTER_NAME} \
    --pod-execution-role-arn $FARGATE_IAM_PROFILE_ARN \
    --fargate-profile-name checkout-profile \
    --selectors '[{"namespace": "checkout", "labels": {"fargate": "yes"}}]' \
    --subnets "[\"$PRIVATE_SUBNET_1\", \"$PRIVATE_SUBNET_2\", \"$PRIVATE_SUBNET_3\"]"

$ aws eks wait fargate-profile-active --cluster-name ${EKS_CLUSTER_NAME} \
    --fargate-profile-name checkout-profile
```

次に、Fargate プロファイルを調査できます：

```bash wait=120
$ aws eks describe-fargate-profile \
    --cluster-name $EKS_CLUSTER_NAME \
    --fargate-profile-name checkout-profile
{
    "fargateProfile": {
        "fargateProfileName": "checkout-profile",
        "fargateProfileArn": "arn:aws:eks:us-west-2:1234567890:fargateprofile/eks-workshop/checkout-profile/92c4e2e3-50cd-773c-1c32-52e4d44cd0ca",
        "clusterName": "eks-workshop",
        "createdAt": "2023-08-05T12:57:58.022000+00:00",
        "podExecutionRoleArn": "arn:aws:iam::1234567890:role/eks-workshop-fargate",
        "subnets": [
            "subnet-01c3614cdd385a93c",
            "subnet-0e392224ce426565a",
            "subnet-07f8a6fda62ec83df"
        ],
        "selectors": [
            {
                "namespace": "checkout",
                "labels": {
                    "fargate": "yes"
                }
            }
        ],
        "status": "ACTIVE",
        "tags": {}
    }
}
```
