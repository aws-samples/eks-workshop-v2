---
title: "新しいノードグループのプロビジョニング"
sidebar_position: 20
tmdTranslationSourceHash: "973e02ea92db1a8a09f9aa26b1d1fe67"
---

EKSマネージドノードグループを作成します：

```bash wait=10
$ aws eks create-nodegroup --region $AWS_REGION \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking \
  --instance-types t3.medium --node-role $CUSTOM_NETWORKING_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --labels type=customnetworking \
  --scaling-config minSize=1,maxSize=1,desiredSize=1
```

ノードグループの作成には数分かかります。次のコマンドを使用してノードグループの作成が完了するのを待つことができます：

```bash timeout=300
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
```

これが完了すると、EKSクラスターに登録された新しいノードを確認できます：

```bash
$ kubectl get nodes -L eks.amazonaws.com/nodegroup
NAME                                            STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-104-242.us-west-2.compute.internal     Ready    <none>   84m   vVAR::KUBERNETES_NODE_VERSION     default
ip-10-42-110-28.us-west-2.compute.internal      Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION     custom-networking
ip-10-42-139-60.us-west-2.compute.internal      Ready    <none>   65m   vVAR::KUBERNETES_NODE_VERSION     default
ip-10-42-180-105.us-west-2.compute.internal     Ready    <none>   65m   vVAR::KUBERNETES_NODE_VERSION     default
```

新しいノードグループの名前でラベル付けされた1つの新しいノードがプロビジョニングされていることがわかります。
