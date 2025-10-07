---
title: Gravitonノードを作成する
sidebar_position: 10
kiteTranslationSourceHash: 796beaca8412816af0badbdbcfedf8b1
---

この演習では、Gravitonベースのインスタンスを使用した別のマネージドノードグループをプロビジョニングし、そこにテイントを適用します。

まず、クラスター内のノードの現在の状態を確認しましょう：

```bash
$ kubectl get nodes -L kubernetes.io/arch
NAME                                           STATUS   ROLES    AGE     VERSION                ARCH
ip-192-168-102-2.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-137-20.us-west-2.compute.internal   Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-19-31.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
```

出力には、各ノードのCPUアーキテクチャを示す列とともに既存のノードが表示されています。これらはすべて現在`amd64`ノードを使用しています。

:::note
まだテイントは構成しません。これは後で行います。
:::

次のコマンドでGravitonノードグループを作成します：

```bash timeout=600 hook=configure-taints
$ aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  --node-role $GRAVITON_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types t4g.medium \
  --ami-type AL2023_ARM_64_STANDARD \
  --scaling-config minSize=1,maxSize=3,desiredSize=1 \
  --disk-size 20
```

:::tip
aws `eks wait nodegroup-active`コマンドを使用して、特定のEKSノードグループがアクティブになり使用可能になるまで待機できます。このコマンドはAWS CLIの一部であり、指定されたノードグループが正常に作成され、関連するすべてのインスタンスが実行され準備ができていることを確認するために使用できます。

```bash wait=30 timeout=300
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

:::

新しいマネージドノードグループが**Active**になったら、次のコマンドを実行します：

```bash
$ kubectl get nodes \
    --label-columns eks.amazonaws.com/nodegroup,kubernetes.io/arch

NAME                                          STATUS   ROLES    AGE    VERSION               NODEGROUP   ARCH
ip-192-168-102-2.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-137-20.us-west-2.compute.internal  Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-19-31.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-10-42-172-231.us-west-2.compute.internal   Ready    <none>   2m5s   vVAR::KUBERNETES_NODE_VERSION     graviton    arm64
```

以下のコマンドは、マネージドノードグループ名`graviton`に一致する`eks.amazonaws.com/nodegroup`ラベルを持つすべてのノードをクエリするために`--selector`フラグを使用しています。`--label-columns`フラグを使用すると、`eks.amazonaws.com/nodegroup`ラベルの値とプロセッサアーキテクチャを出力に表示することもできます。`ARCH`列にはGraviton `arm64`プロセッサを実行しているテイント付きノードグループが表示されていることに注意してください。

ノードの現在の構成を調べてみましょう。次のコマンドは、マネージドノードグループの一部であるすべてのノードの詳細を一覧表示します。

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton
Name:               ip-10-42-12-233.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-0b55230f107a87100
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-07afc97c4940b6622
                    kubernetes.io/arch=arm64
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             <none>
[...]
```

いくつか注目すべき点があります：

1. EKSは、OS種類、マネージドノードグループ名、インスタンスタイプなどを含む、簡単なフィルタリングのための特定のラベルを自動的に追加します。特定のラベルはEKSにすでに用意されていますが、AWSではマネージドノードグループレベルでカスタムラベルのセットを構成することもできます。これにより、ノードグループ内のすべてのノードに一貫したラベルが付与されます。`kubernetes.io/arch`ラベルは、ARM64 CPUアーキテクチャを持つEC2インスタンスを実行していることを示しています。
2. 現在、調査対象のノードに対して設定されているテイントはなく、`Taints: <none>`のスタンザで示されています。

## マネージドノードグループのテイントの構成

[ここ](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts)で説明されているように、`kubectl` CLIを使用してノードにテイントを追加することは簡単ですが、管理者は基盤となるノードグループがスケールアップまたはスケールダウンするたびにこの変更を行う必要があります。この課題を克服するために、AWSはマネージドノードグループに`labels`と`taints`の両方を追加することをサポートしており、MNG内のすべてのノードに関連するラベルとテイントが自動的に構成されるようにします。

それでは、事前設定済みのマネージドノードグループ`graviton`にテイントを追加しましょう。このテイントには`key=frontend`、`value=true`、`effect=NO_EXECUTE`を設定します。これにより、一致する許容がない場合、テイント付きマネージドノードグループですでに実行されているポッドが排除され、適切な許容がない場合は新しいポッドがこのマネージドノードグループにスケジュールされないことが保証されます。

まず、次の`aws` cliコマンドを使用してマネージドノードグループに`taint`を追加しましょう：

```bash wait=20
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME --nodegroup-name graviton \
    --taints "addOrUpdateTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
{
    "update": {
        "id": "488a2b7d-9194-3032-974e-2f1056ef9a1b",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "TaintsToAdd",
                "value": "[{\"effect\":\"NO_EXECUTE\",\"value\":\"true\",\"key\":\"frontend\"}]"
            }
        ],
        "createdAt": "2022-11-09T15:20:10.519000+00:00",
        "errors": []
    }
}
```

次のコマンドを実行して、ノードグループがアクティブになるのを待ちます。

```bash timeout=180
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

テイントの追加、削除、または置き換えは、[`aws eks update-nodegroup-config`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) CLIコマンドを使用してマネージドノードグループの構成を更新することで行うことができます。これは、`--taints`コマンドフラグに`addOrUpdateTaints`または`removeTaints`とテイントのリストを渡すことで実行できます。

:::tip
`eksctl` CLIを使用してマネージドノードグループにテイントを構成することもできます。詳細は[ドキュメント](https://eksctl.io/usage/nodegroup-taints/)を参照してください。
:::

テイント構成では`effect=NO_EXECUTE`を使用しました。マネージドノードグループは現在、テイントの`effect`に対して以下の値をサポートしています：

- `NO_SCHEDULE` - これはKubernetesの`NoSchedule`テイント効果に対応します。これにより、一致する許容を持たないすべてのポッドを拒否するテイントでマネージドノードグループが構成されます。実行中のポッドはマネージドノードグループのノードから**排除されません**。
- `NO_EXECUTE` - これはKubernetesの`NoExecute`テイント効果に対応します。このテイントで構成されたノードが新しくスケジュールされるポッドを拒否するだけでなく、一致する許容がない実行中のポッドも**排除する**ことができます。
- `PREFER_NO_SCHEDULE` - これはKubernetesの`PreferNoSchedule`テイント効果に対応します。可能であれば、EKSはこのテイントを許容しないポッドをノードにスケジュールするのを避けます。

次のコマンドを使用して、テイントがマネージドノードグループに正しく構成されているかを確認できます：

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  | jq .nodegroup.taints
[
  {
    "key": "frontend",
    "value": "true",
    "effect": "NO_EXECUTE"
  }
]
```

:::info

マネージドノードグループの更新とラベル・テイントの伝播には通常数分かかります。テイントが構成されていないか、`null`値が表示される場合は、上記のコマンドを再度試す前に数分待ってください。

:::

`kubectl` cliコマンドで確認すると、テイントが関連するノードに正しく伝播されていることがわかります：

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton | grep Taints
Taints:             frontend=true:NoExecute
```
