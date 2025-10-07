---
title: "ハイブリッドノードの接続"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 20 # used by test framework
kiteTranslationSourceHash: a169f0cedba0153cc344d6f6e644aefa
---

Amazon EKS ハイブリッドノードは、AWS SSM ハイブリッドアクティベーションまたは AWS IAM Roles Anywhere によって提供される一時的な IAM 認証情報を使用して Amazon EKS クラスターで認証を行います。このワークショップでは、SSM ハイブリッドアクティベーションを使用します。

ハイブリッドアクティベーションを作成して `ACTIVATION_ID` と `ACTIVATION_CODE` 環境変数を設定するために、次のコマンドを実行します：

```bash timeout=300 wait=30
$ export ACTIVATION_JSON=$(aws ssm create-activation \
--default-instance-name hybrid-ssm-node \
--iam-role $HYBRID_ROLE_NAME \
--registration-limit 1 \
--region $AWS_REGION)
$ export ACTIVATION_ID=$(echo $ACTIVATION_JSON | jq -r ".ActivationId")
$ export ACTIVATION_CODE=$(echo $ACTIVATION_JSON | jq -r ".ActivationCode")
```

アクティベーションが作成されたので、次はインスタンスをクラスターに接続する際に参照される `NodeConfig` を作成します。

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/nodeconfig.yaml" paths="spec.cluster,spec.hybrid.ssm"}

1. `$EKS_CLUSTER_NAME` と `$AWS_REGION` 環境変数を使用して、ターゲットの EKS クラスター `name` と `region` を指定
2. 前のステップで作成した `$ACTIVATION_CODE` と `$ACTIVATION_ID` 環境変数を使用して、SSM の `activationCode` と `activationId` を指定

```bash
$ cat ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/nodeconfig.yaml \
| envsubst > nodeconfig.yaml
```

`nodeconfig.yaml` をハイブリッドノードインスタンスにコピーしましょう。

```bash timeout=300 wait=30
$ mkdir -p ~/.ssh/
$ ssh-keyscan -H $HYBRID_NODE_IP &> ~/.ssh/known_hosts
$ scp -i private-key.pem nodeconfig.yaml ubuntu@$HYBRID_NODE_IP:/home/ubuntu/nodeconfig.yaml
```

次に、EC2インスタンス上で `nodeadm` を使用してハイブリッドノードの依存関係をインストールしましょう。これには containerd、kubelet、kubectl、AWS SSM または AWS IAM Roles Anywhere コンポーネントが含まれます。インストールされるコンポーネントとファイルの場所については、ハイブリッドノードの [nodeadm リファレンス](https://docs.aws.amazon.com/eks/latest/userguide/hybrid-nodes-nodeadm.html) を参照してください。

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm install $EKS_CLUSTER_VERSION --credential-provider ssm"
```

依存関係がインストールされ、`nodeconfig.yaml` が配置されたので、インスタンスをハイブリッドノードとして初期化します。

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm init -c file://nodeconfig.yaml"
```

ハイブリッドノードがクラスターに正常に参加したか確認しましょう。認証情報プロバイダーとしてSystems Managerを使用しているため、ハイブリッドノードには `mi-` というプレフィックスが付いています。

```bash timeout=300 wait=30
$ kubectl get nodes
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          NotReady   <none>   5m     v1.31.4-eks-aeac579
```

素晴らしい！ノードは表示されていますが、`NotReady` のステータスになっています。これは、ワークロードを提供するためにハイブリッドノードが準備完了になるには CNI をインストールする必要があるからです。まず、Cilium Helm リポジトリを追加しましょう。

```bash timeout=300 wait=30
$ helm repo add cilium https://helm.cilium.io/
```

次に、Cilium helm チャートに入力として提供する設定値を見てみましょう：

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/cilium-values.yaml" paths="affinity.nodeAffinity,ipam.mode,ipam.operator.clusterPoolIPv4MaskSize,ipam.operator.clusterPoolIPv4PodCIDRList,operator.replicas,operator.affinity,operator.unmanagedPodWatcher.restart,envoy.enabled"}

1. この `affinity.nodeAffinity` 設定は、`eks.amazonaws.com/compute-type` によってノードをターゲットにし、各ノード上でネットワーキングを処理するメイン CNI デーモンセットポッドが `hybrid` ノードでのみ実行されるようにします
2. `ipam.mode` を `cluster-pool` に設定して、ポッド IP 割り当てにクラスター全体の IP プールを使用します
3. `clusterPoolIPv4MaskSize: 25` を設定して、ノードごとに割り当てられる `/25` サブネット（128 IP アドレス）を指定します
4. `clusterPoolIPv4PodCIDRList` を `10.53.0.0/16` に設定して、ハイブリッドノードポッド用の専用 CIDR を指定します
5. `replicas: 1` を設定して、オペレーターのインスタンスが 1 つ実行されるように指定します
6. この `affinity.nodeAffinity` 設定は、`eks.amazonaws.com/compute-type` によってノードをターゲットにし、各ノード上で CNI 設定を管理するメイン CNI オペレーターポッドが `hybrid` ノードでのみ実行されるようにします
7. `unmanagedPodWatcher.restart: false` を設定して、ポッド再起動の監視を無効にします
8. `envoy.enabled: false` を設定して、Envoy プロキシ統合を無効にします

この構成を使用して Cilium をインストールしましょう。

```bash timeout=300 wait=30
$ helm install cilium cilium/cilium \
--version 1.17.1 \
--namespace cilium \
--create-namespace \
--values ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/cilium-values.yaml
```

Cilium をインストールした後、ハイブリッドノードは正常な状態で準備完了になるはずです。

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready nodes --all --timeout=2m
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          Ready      <none>   5m   v1.31.4-eks-aeac579
```

以上です！これでクラスター内でハイブリッドノードが稼働しています。
