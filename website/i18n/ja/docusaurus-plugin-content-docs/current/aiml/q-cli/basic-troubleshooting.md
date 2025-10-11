---
title: "基本的なトラブルシューティング"
sidebar_position: 22
kiteTranslationSourceHash: 644742bac63161796f45e2a3b85b3e12
---

このセクションでは、Amazon Q CLIと[Amazon EKS用のMCPサーバー](https://awslabs.github.io/mcp/servers/eks-mcp-server/)を使用して、EKSクラスタの問題をトラブルシューティングします。

まず、失敗するポッドをクラスターにデプロイしましょう。その後、Amazon Q CLIを使用してトラブルシューティングを行います。

::yaml{file="manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml
```

ポッドの状態を確認します：

```bash
$ kubectl get pods -n default
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

ご覧のとおり、クラスター内にpending状態のポッドがあります。Q CLIを使用して原因を調査しましょう。

新しいQ CLIセッションを開始します：

```bash test=false
$ q chat
```

Q CLIに問題のトラブルシューティングを依頼するために、次の質問を入力します：

```text
I have a pod stuck in a pending state in my eks-workshop cluster. Find the cause of the failure and provide me with a summary of the approach to solve it.
```

この問い合わせに対応するために、Q CLIはMCPサーバーからさまざまなツールを使用します。実行する可能性のあるステップには以下が含まれます：

- `list_k8s_resources`ツールを使用してクラスター内の失敗しているポッドを特定する
- `manage_k8s_resource`ツールを使用してポッドの詳細情報を取得する
- `get_k8s_events`ツールを使用してポッドのKubernetesイベント履歴を検査する
- `manage_k8s_resource`ツールを使用して関連するKubernetesリソースの詳細を取得する
- `search_eks_troubleshoot_guide`ツールを使用してEKSトラブルシューティングガイドを参照する

Q CLIは、クラスターから収集したデータに基づいて分析結果を提供します。

<details>
  <summary>サンプルレスポンスを展開</summary>

```text
## Pod Pending Issue Summary

Problem: Pod failing-pod in the default namespace is stuck in pending state.

Root Cause: The pod references a PersistentVolumeClaim named my-pvc that doesn't exist.

Error Details:
• Status: Unschedulable
• Message: persistentvolumeclaim "my-pvc" not found
• 0/3 nodes available due to missing PVC

Solutions:
1. Create the missing PVC - Create a PersistentVolumeClaim named my-pvc using the available gp2 StorageClass
2. Remove the volume requirement - Edit the pod to remove the volume mount and PVC reference
3. Delete the pod - If it's a test pod that's no longer needed

Available Resources:
• StorageClass gp2 is available for creating PVCs
• 3 worker nodes are healthy and available

The pod will automatically schedule once the PVC is created or the volume requirement is removed.
```

</details>

Q CLIセッションを終了するには、次のコマンドを入力します：

```text
/quit
```

次のセクションでは、より複雑なトラブルシューティングのシナリオを探ります。
