---
title: "基本的なトラブルシューティング"
sidebar_position: 22
tmdTranslationSourceHash: 'e746980b9c7aafef1b227fd18a9fb80d'
---

このセクションでは、Kiro CLI と [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) を使用して、EKS クラスター内の問題をトラブルシューティングします。

まず、クラスターに失敗する Pod をデプロイし、その後 Kiro CLI を使用してトラブルシューティングを行います。

::yaml{file="manifests/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml
```

Pod のステータスを確認します：

```bash
$ kubectl get pods -n default
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

ご覧のとおり、クラスター内に Pending 状態の Pod があります。Kiro CLI を使用して原因を調査しましょう。

新しい Kiro CLI セッションを開始します：

```bash test=false
$ kiro-cli chat
```

次の質問を入力して、Kiro CLI に問題のトラブルシューティングを依頼します：

```text
I have a pod stuck in a pending state in my eks-workshop cluster. Find the cause of the failure and provide me with a summary of the approach to solve it.
```

このプロンプトに対処するために、Kiro CLI は MCP サーバーからさまざまなツールを使用します。実行する可能性のあるステップには以下が含まれます：

- `list_k8s_resources` ツールを使用してクラスター内の失敗している Pod を特定する
- `manage_k8s_resource` ツールを使用して Pod の詳細を取得する
- `get_k8s_events` ツールを使用して Pod の Kubernetes イベント履歴を調査する
- `manage_k8s_resource` ツールを使用して関連する Kubernetes リソースの詳細を取得する
- `search_eks_troubleshoot_guide` ツールを使用して EKS トラブルシューティングガイドを取得して参照する

Kiro CLI は、クラスターから収集したデータに基づいて分析を提供します。

<details>
  <summary>サンプルレスポンスを展開</summary>

```text

  Diagnosis
  
  Pod: failing-pod in the default namespace
  
  Root Cause: The pod is unschedulable because it references a PersistentVolumeClaim named my-pvc that does not exist. The scheduler message confirms:
  
  │ 0/3 nodes are available: persistentvolumeclaim "my-pvc" not found.
  
  I verified that there are zero PVCs in the default namespace, so the claim the pod depends on was never created.
  
  Resolution
  
  Create the missing PersistentVolumeClaim. Here's an example that would satisfy the pod's volume mount:
  
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: my-pvc
    namespace: default
  spec:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
  
  Once the PVC is created and bound (EKS Auto Mode or a CSI driver like EBS CSI will dynamically provision the volume if a default StorageClass exists), the scheduler will be able to place the pod on a node and it will transition out of Pending.
  
  If you don't have a default StorageClass, you can check with list_k8s_resources for StorageClasses and either set one as default or explicitly specify storageClassName in the PVC. Would you like me to create this PVC for you?

▸ Credits: 0.66 • Time: 1m 14s
```

</details>

Kiro CLI セッションを終了するには、次のコマンドを入力します：

```text
/quit
```

次に、失敗した Pod を削除します： 

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```

次のセクションでは、より複雑なトラブルシューティングシナリオを探ります。

