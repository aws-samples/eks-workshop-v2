---
title: Fargateの有効化
sidebar_position: 10
kiteTranslationSourceHash: 14271fb060885fe2bc8ef31b0d6211b0
---

Fargateでクラスター内のPodをスケジュールする前に、起動時にどのPodがFargateを使用するかを指定する少なくとも1つのFargateプロファイルを定義する必要があります。

管理者として、Fargateプロファイルを使用してどのPodがFargateで実行されるかを宣言できます。これはプロファイルのセレクターを通じて行うことができます。各プロファイルには最大5つのセレクターを追加できます。各セレクターには名前空間とオプションのラベルが含まれています。すべてのセレクターに対して名前空間を定義する必要があります。ラベルフィールドは複数のオプションのキーと値のペアで構成されています。セレクターに一致するPodはFargateでスケジュールされます。Podは、セレクターで指定された名前空間とラベルを使用して一致します。ラベルなしで名前空間セレクターが定義されている場合、Amazon EKSはその名前空間で実行されるすべてのPodをプロファイルを使用してFargateにスケジュールしようとします。スケジュールされるPodがFargateプロファイル内のいずれかのセレクターと一致する場合、そのPodはFargateでスケジュールされます。

PodがFargateプロファイルを複数一致する場合、次のKubernetesラベルをPod仕様に追加することで、どのプロファイルを使用するかを指定できます：`eks.amazonaws.com/fargate-profile: my-fargate-profile`。Podはそのプロファイルのセレクターと一致する必要があり、Fargateでスケジュールされます。Kubernetesのアフィニティ/アンチアフィニティルールはAmazon EKS FargatePodには適用されず、必要ありません。

まずは、EKSクラスターにFargateプロファイルを追加しましょう。以下のコマンドは、次の特性を持つ`checkout-profile`というFargateプロファイルを作成します：

1. ラベル`fargate: yes`を持つ`checkout`名前空間内のPodをターゲットにする
2. PodをVPCのプライベートサブネットに配置する
3. FargateインフラストラクチャにIAMロールを適用して、ECRからイメージを取得したり、CloudWatchにログを書き込んだりできるようにする

以下のコマンドでプロファイルを作成します。これには数分かかります：

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

これでFargateプロファイルを検査できます：

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

