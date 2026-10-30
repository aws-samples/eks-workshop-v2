---
title: はじめに
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceでワークロードを実行する基本を学びましょう。"
tmdTranslationSourceHash: b1aa6cc2b0129e0dbca8a43899c93dd0
---

::required-time

EKSワークショップの最初のハンズオンラボへようこそ。この演習の目的は、IDE環境に必要な設定を準備し、その構造を探索することです。

始める前に、IDE環境とEKSクラスターを準備するために次のコマンドを実行する必要があります：

:::tip このセクションのために環境を準備してください：

```bash
$ prepare-environment introduction/getting-started
```
このコマンドは、EKS WorkshopのGitリポジトリをIDE環境にクローンします。
:::

<details>
<summary>prepare-environmentは何をするのですか？（クリックして展開）</summary>

`prepare-environment`コマンドは、各ワークショップモジュールのラボ環境をセットアップする重要なツールです。バックグラウンドで次のことを実行します：

- **リポジトリのセットアップ**：GitHubから最新のEKS Workshopコンテンツを`/eks-workshop/repository`にダウンロードし、Kubernetesマニフェストを`~/environment/eks-workshop`にリンクします
- **クラスターのリセットとクリーンアップ**：サンプルの小売アプリケーションを基本状態にリセットします。以前のラボからの残存リソースを削除し、EKS管理ノードグループを初期サイズ（3ノード）に復元します。
- **ラボ固有のインフラストラクチャ**：Terraformを使用して必要な追加AWSリソースを作成し、必要なKubernetesマニフェストをデプロイし、環境変数を設定し、必要なアドオンやコンポーネントをインストールすることで、対象モジュールを使用可能な状態にします。

</details>

## ワークショップの構造

`prepare-environment`を実行した後、`~/environment/eks-workshop/`でワークショップ資料にアクセスできます。ワークショップは、任意の順序で完了できるモジュール式のセクションで構成されています。

## EKSクラスターの探索

環境の準備が整ったので、プロビジョニングされたEKSクラスターを探索しましょう。次のコマンドを実行して、クラスターに慣れてください：

### クラスター情報

まず、クラスター接続を確認し、基本情報を取得しましょう：

```bash
$ kubectl cluster-info
Kubernetes control plane is running at https://XXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.us-west-2.eks.amazonaws.com
CoreDNS is running at https://XXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.us-west-2.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

クラスターバージョンを確認します
```bash
$ kubectl version
Client Version: v1.33.5
Kustomize Version: v5.6.0
Server Version: v1.33.5-eks-113cf36
```

クラスター内のワーカーノードを確認します

```bash
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE   VERSION               INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                   CONTAINER-RUNTIME
ip-10-42-121-153.us-west-2.compute.internal   Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.121.153   <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
ip-10-42-141-241.us-west-2.compute.internal   Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.141.241   <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
ip-10-42-183-73.us-west-2.compute.internal    Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.183.73    <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
```

これにより、ワーカーノード、そのKubernetesバージョン、内部/外部IP、および使用されているコンテナランタイムが表示されます。

### クラスターコンポーネントの探索

クラスターで実行されているシステムコンポーネントを見てみましょう：

```bash
$ kubectl get pods -n kube-system
NAME                              READY   STATUS    RESTARTS   AGE
aws-node-8cz4d                    2/2     Running   0          26h
aws-node-jlg4q                    2/2     Running   0          26h
aws-node-vdc56                    2/2     Running   0          26h
coredns-7bf648ff5d-4fqv9          1/1     Running   0          26h
coredns-7bf648ff5d-bfwwf          1/1     Running   0          26h
kube-proxy-77ln2                  1/1     Running   0          26h
kube-proxy-7bwbj                  1/1     Running   0          26h
kube-proxy-jnhfx                  1/1     Running   0          26h
metrics-server-7fb96f5556-2k4lh   1/1     Running   0          26h
metrics-server-7fb96f5556-mpj78   1/1     Running   0          26h
```

次のような重要なコンポーネントが表示されます：
- **CoreDNS** - クラスターにDNSサービスを提供します
- **AWS Load Balancer Controller** - サービス用のAWSロードバランサーを管理します
- **VPC CNI** - VPC内のPodネットワーキングを処理します
- **kube-proxy** - 各ノード上のネットワークルールを管理します

## サンプルアプリケーションのデプロイ

小売店アプリケーションをデプロイして、Kubernetesの動作を見てみましょう。`kubectl`に組み込まれているKustomizeを使用します：

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

これが完了したら、`kubectl wait`を使用して、続行する前にすべてのコンポーネントが起動していることを確認できます：

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

各アプリケーションコンポーネント用のNamespaceが作成されます：

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
ui         Active   62s
```

コンポーネント用に作成されたすべてのDeploymentも確認できます：

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                READY   UP-TO-DATE   AVAILABLE   AGE
carts       carts               1/1     1            1           90s
carts       carts-dynamodb      1/1     1            1           90s
catalog     catalog             1/1     1            1           7m46s
checkout    checkout            1/1     1            1           90s
checkout    checkout-redis      1/1     1            1           90s
orders      orders              1/1     1            1           90s
orders      orders-postgresql   1/1     1            1           90s
ui          ui                  1/1     1            1           90s
```

サンプルアプリケーションがデプロイされ、このワークショップの残りのラボで使用する基盤を提供する準備ができました！

## 次は何をしますか？

EKSクラスターの準備ができ、サンプルアプリケーションがデプロイされました！学習目標に基づいて、任意のワークショップモジュールに進むことができます。

:::tip
各モジュールは独立しており、必要なリソースをセットアップするための独自の`prepare-environment`コマンドが含まれています。任意の順序で完了できます！
:::
