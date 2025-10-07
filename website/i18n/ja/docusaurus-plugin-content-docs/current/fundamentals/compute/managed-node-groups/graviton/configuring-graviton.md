---
title: Gravitonノードの作成
sidebar_position: 10
kiteTranslationSourceHash: 796beaca8412816af0badbdbcfedf8b1
---

この演習では、Gravitonベースのインスタンスを持つ別のマネージドノードグループをプロビジョニングし、それにTaintを適用します。

まず、クラスター内で利用可能なノードの現在の状態を確認しましょう：

```bash
$ kubectl get nodes -L kubernetes.io/arch
NAME                                           STATUS   ROLES    AGE     VERSION                ARCH
ip-192-168-102-2.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-137-20.us-west-2.compute.internal   Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-19-31.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
```

この出力には、各ノードのCPUアーキテクチャを示す列があります。現在はすべて`amd64`ノードを使用しています。

:::note
この段階ではまだTaintを設定しません。これは後ほど行います。
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
aws `eks wait nodegroup-active` コマンドを使用して、特定のEKSノードグループがアクティブになり使用可能になるまで待つことができます。このコマンドはAWS CLIの一部であり、指定されたノードグループが正常に作成され、関連するすべてのインスタンスが実行中で準備完了していることを確認するために使用できます。

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

以下のコマンドは、`--selector`フラグを使用して、マネージドノードグループ名`graviton`と一致する`eks.amazonaws.com/nodegroup`ラベルを持つすべてのノードを照会します。`--label-columns`フラグを使うと、`eks.amazonaws.com/nodegroup`ラベルの値とプロセッサアーキテクチャを出力に表示できます。`ARCH`列には、TaintされたノードグループがGraviton `arm64`プロセッサで実行されていることが示されています。

ノードの現在の構成を確認しましょう。以下のコマンドは、マネージドノードグループに属するすべてのノードの詳細を表示します。

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

1. EKSは、OSタイプ、マネージドノードグループ名、インスタンスタイプなど、フィルタリングを容易にするために特定のラベルを自動的に追加します。EKSにはデフォルトで特定のラベルが提供されていますが、AWSではマネージドノードグループレベルで独自のカスタムラベルセットを設定できます。これにより、ノードグループ内のすべてのノードに一貫したラベルが付けられます。`kubernetes.io/arch`ラベルは、ARM64 CPUアーキテクチャを持つEC2インスタンスを実行していることを示しています。
2. 現在、`Taints: <none>`の部分に示されているように、探索されたノードには構成されたTaintはありません。

## マネージドノードグループのTaint設定

[ここ](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts)で説明されているように、`kubectl` CLIを使用してノードにTaintを適用するのは簡単ですが、基礎となるノードグループがスケールアップまたはスケールダウンするたびに、管理者がこの変更を行う必要があります。この課題を克服するために、AWSはマネージドノードグループに`labels`と`taints`の両方を追加することをサポートしており、MNG内のすべてのノードに関連するラベルとTaintが自動的に設定されます。

それでは、事前に構成されたマネージドノードグループ`graviton`にTaintを追加しましょう。このTaintには`key=frontend`、`value=true`、`effect=NO_EXECUTE`が設定されます。これにより、一致するTolerationを持たないTaintされたマネージドノードグループ上で既に実行されているPodは排除され、また適切なTolerationなしでは新しいPodはこのマネージドノードグループにスケジュールされません。

まず、以下の`aws` cliコマンドを使用してマネージドノードグループに`taint`を追加しましょう：

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

ノードグループがアクティブになるのを待つために、次のコマンドを実行します。

```bash timeout=180
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

Taintの追加、削除、置換は、[`aws eks update-nodegroup-config`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) CLIコマンドを使用してマネージドノードグループの構成を更新することで実行できます。これは、`--taints`コマンドフラグに`addOrUpdateTaints`または`removeTaints`とTaintのリストを渡すことで行います。

:::tip
`eksctl` CLIを使用してマネージドノードグループにTaintを設定することもできます。詳細については[ドキュメント](https://eksctl.io/usage/nodegroup-taints/)を参照してください。
:::

Taintの設定では`effect=NO_EXECUTE`を使用しました。マネージドノードグループは現在、Taintの`effect`に対して以下の値をサポートしています：

- `NO_SCHEDULE` - これはKubernetesの`NoSchedule` Taint効果に対応します。一致するTolerationを持たないすべてのPodを拒絶するTaintでマネージドノードグループを構成します。実行中のすべてのPodは**マネージドノードグループのノードから排除されません**。
- `NO_EXECUTE` - これはKubernetesの`NoExecute` Taint効果に対応します。このTaintで構成されたノードが、新しくスケジュールされたPodを拒絶するだけでなく、**一致するTolerationのない実行中のPodも排除**することを許可します。
- `PREFER_NO_SCHEDULE` - これはKubernetesの`PreferNoSchedule` Taint効果に対応します。可能であれば、EKSはこのTaintを許容しないPodをノードにスケジュールしないようにします。

以下のコマンドを使用して、マネージドノードグループのTaintが正しく設定されているか確認できます：

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

マネージドノードグループの更新とラベルとTaintの伝播には通常数分かかります。Taintが設定されていないか、`null`値が表示される場合は、上記のコマンドを再試行する前に数分待ってください。

:::

`kubectl` cliコマンドで確認すると、Taintが関連ノードに正しく伝播されていることも確認できます：

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton | grep Taints
Taints:             frontend=true:NoExecute
```
