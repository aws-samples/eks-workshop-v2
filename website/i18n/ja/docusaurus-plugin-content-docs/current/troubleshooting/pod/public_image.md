---
title: "ImagePullBackOff - パブリックイメージ"
sidebar_position: 72
tmdTranslationSourceHash: "41d5d8121672805ce38786d2e304bdeb"
---

このセクションでは、ECRパブリックイメージに関するPodのImagePullBackOffエラーのトラブルシューティング方法を学びます。まず、デプロイメントが作成されているか確認し、トラブルシューティングのシナリオを開始できるようにしましょう。

```bash
$ kubectl get deployment ui-new -n default
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
ui-new   0/1     1            0           75s
```

:::info
同じ出力が得られた場合は、トラブルシューティングを開始する準備ができています。
:::

このトラブルシューティングセクションでの課題は、デプロイメントui-newが0/1の準備状態にある原因を特定し、修正してデプロイメントがPodを1つ準備して実行している状態にすることです。

## トラブルシューティングを始めましょう

### ステップ1：Podのステータスを確認する

まず、`kubectl`ツールを使用してPodのステータスを確認する必要があります。

```bash
$ kubectl get pods -l app=app-new
NAME                      READY   STATUS             RESTARTS   AGE
ui-new-5654dd8969-7w98k   0/1     ImagePullBackOff   0          13s
```

### ステップ2：Podを詳しく調べる

PodのステータスがImagePullBackOffとして表示されていることがわかります。イベントを確認するためにPodを詳細に調べてみましょう。

```bash expectError=true timeout=20
$ POD=`kubectl get pods -l app=app-new -o jsonpath='{.items[*].metadata.name}'`
$ kubectl describe pod $POD | awk '/Events:/,/^$/'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  48s                default-scheduler  Successfully assigned default/ui-new-5654dd8969-7w98k to ip-10-42-33-232.us-west-2.compute.internal
  Normal   BackOff    23s (x2 over 47s)  kubelet            Back-off pulling image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1"
  Warning  Failed     23s (x2 over 47s)  kubelet            Error: ImagePullBackOff
  Normal   Pulling    12s (x3 over 47s)  kubelet            Pulling image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1"
  Warning  Failed     12s (x3 over 47s)  kubelet            Failed to pull image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": rpc error: code = NotFound desc = failed to pull and unpack image "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": failed to resolve reference "public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1": public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1: not found
  Warning  Failed     12s (x3 over 47s)  kubelet            Error: ErrImagePull
```

Podのイベントから、エラーコードNotFoundで「Failed to pull image」警告が表示されています。これは、Pod/デプロイメント仕様で参照されているイメージがそのパスに見つからなかったことを示しています。

### ステップ3：イメージ参照を確認する

Podが使用しているイメージを確認しましょう。

```bash
$ kubectl get pod $POD -o jsonpath='{.spec.containers[*].image}'
public.ecr.aws/aws-containers/retailing-store-sample-ui:1.2.1
```

イメージURIから、このイメージはAWSのパブリックECRリポジトリから参照されていることがわかります。

### ステップ4：イメージの存在を確認する

[aws-containers ECR](https://gallery.ecr.aws/aws-containers)でretailing-store-sample-uiという名前でタグ1.2.1が付いたイメージが存在するかどうかを確認してみましょう。「retailing-store-sample-ui」を検索すると、そのようなイメージリポジトリが表示されないことがわかります。また、ブラウザでイメージURIを使用して、パブリックECRでイメージの存在を簡単に確認することもできます。私たちのケースでは、[image-uri](https://gallery.ecr.aws/aws-containers/retailing-store-sample-ui)に「Repository not found」（リポジトリが見つかりません）というメッセージが表示されます。

![RepoDoesNotExist](/docs/troubleshooting/pod/rep-not-found.webp)

### ステップ5：正しいイメージでデプロイメントを更新する

この問題を解決するには、正しいイメージ参照でデプロイメント/Pod仕様を更新する必要があります。私たちのケースでは、それはpublic.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1です。

#### 5.1. イメージが存在するか確認する

デプロイメントを更新する前に、前述の方法でこのイメージが存在するかどうかを確認しましょう。つまり、[image-uri](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)にアクセスします。retail-store-sample-uiイメージが1.2.1を含む複数のタグで利用可能であることが確認できるはずです。

![RepoExist](/docs/troubleshooting/pod/repo-found.webp)

#### 5.1. デプロイメントのイメージを正しい参照で更新する

```bash
$ kubectl patch deployment ui-new --patch '{"spec": {"template": {"spec": {"containers": [{"name": "ui", "image": "public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1"}]}}}}'
deployment.apps/ui-new patched
```

### ステップ6：修正を確認する

新しいPodが作成され、正常に実行されていることを確認します。

```bash timeout=180 hook=fix-1 hookTimeout=600 wait=20
$ kubectl get pods -l app=app-new
NAME                     READY   STATUS    RESTARTS   AGE
ui-new-77856467b-2z2s6   1/1     Running   0          13s
```

## まとめ

パブリックイメージに関するPodのImagePullBackOffのトラブルシューティングの一般的なワークフローには以下が含まれます：

- 「not found」、「access denied」または「timeout」などの問題の原因に関する手がかりについて、Podイベントを確認します。
- 「not found」の場合、参照されたパスにイメージが存在することを確認します。
- 「access denied」の場合、ワーカーノードロールの権限を確認します。
- ECRのパブリックイメージでタイムアウトが発生した場合は、ワーカーノードのネットワーク設定がIGW/TGW/NATを介してインターネットに到達するように構成されていることを確認します。

