---
title: "Amazon VPC CNIの設定"
sidebar_position: 10
tmdTranslationSourceHash: e96a86fc4472ec29b1d77c88fbef5105
---

まずはAmazon VPC CNIを設定していきましょう。私たちのVPCは、`100.64.0.0/16`範囲のセカンダリCIDRを追加して再構成されています：

```bash
$ aws ec2 describe-vpcs --vpc-ids $VPC_ID | jq '.Vpcs[0].CidrBlockAssociationSet'
[
  {
    "AssociationId": "vpc-cidr-assoc-0ef3fae4a0abc4a42",
    "CidrBlock": "10.42.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  },
  {
    "AssociationId": "vpc-cidr-assoc-0a6577e1404081aef",
    "CidrBlock": "100.64.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  }
]
```

これにより、デフォルトのCIDR範囲（上記の出力では`10.42.0.0/16`）に加えて使用できる別のCIDR範囲ができました。この新しいCIDR範囲から、Podの実行に使用する3つの新しいサブネットをVPCに追加しました：

```bash
$ echo "The secondary subnet in AZ $SUBNET_AZ_1 is $SECONDARY_SUBNET_1"
$ echo "The secondary subnet in AZ $SUBNET_AZ_2 is $SECONDARY_SUBNET_2"
$ echo "The secondary subnet in AZ $SUBNET_AZ_3 is $SECONDARY_SUBNET_3"
```

カスタムネットワーキングを有効にするには、aws-node DaemonSetの`AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG`環境変数を*true*に設定する必要があります。

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```

次に、Podがデプロイされる各サブネット用の`ENIConfig`カスタムリソースを作成します：

```file
manifests/modules/networking/custom-networking/provision/eniconfigs.yaml
```

これらをクラスターに適用しましょう：

```bash wait=30
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/custom-networking/provision \
  | envsubst | kubectl apply -f-
```

`ENIConfig`オブジェクトが作成されたことを確認します：

```bash
$ kubectl get ENIConfigs
```

最後に、aws-node DaemonSetを更新して、EKSクラスターで作成された新しいAmazon EC2ノードにアベイラビリティーゾーンの`ENIConfig`を自動的に適用するようにします。

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```
