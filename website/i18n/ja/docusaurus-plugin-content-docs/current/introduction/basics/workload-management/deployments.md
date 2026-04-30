---
title: Deployment
sidebar_position: 31
tmdTranslationSourceHash: af538f5b1df8835fc8714ea2de6b80a5
---

# Deployment

**Deployment**は、ステートレスアプリケーションを実行するための最も一般的なワークロードコントローラーです。Deploymentは、アプリケーションが常に希望する数のPodを実行することを保証し、作成、スケーリング、更新、復旧を自動的に処理します。

Podを手動で管理する代わりに、DeploymentによってKubernetesは以下を実行できます：
- **複数の同一Podを実行** - 信頼性と負荷分散のため
- **自動的にスケール** - レプリカ数を調整することで
- **失敗したPodを復旧** - 手動介入なしで
- **ローリング更新を実行** - ダウンタイムなしで
- **簡単にロールバック** - 問題があった場合、以前のバージョンに戻す

### Deploymentの作成

Deploymentを使用して小売ストアのUIをデプロイしましょう：

::yaml{file="manifests/base-application/ui/deployment.yaml" paths="kind,metadata.name,spec.replicas,spec.selector,spec.template" title="deployment.yaml"}

1. `kind: Deployment`: Deploymentコントローラーを定義
2. `metadata.name`: Deploymentの名前（ui）
3. `spec.replicas`: 希望するPod数（この例では1）
4. `spec.selector`: 管理されるPodを見つけるために使用されるラベル
5. `spec.template`: 各Podがどのように見えるべきかを定義するPodテンプレート

Deploymentは、実際のPodが常にこのテンプレートと一致することを保証します。

Deploymentを適用します：
```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/ui
```

### Deploymentの確認

Deploymentのステータスを確認します：
```bash
$ kubectl get deployment -n ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           30s
```

Deploymentによって作成されたPodをリストします：
```bash
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-xyz12   1/1     Running   0          30s
```

詳細情報を取得します：
```bash
$ kubectl describe deployment -n ui ui
```

### Deploymentのスケーリング

5つのレプリカにスケールアップします：
```bash
$ kubectl scale deployment -n ui ui --replicas=5
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-abc12   1/1     Running   0          2m
ui-6d5bb7b9c8-def34   1/1     Running   0          12s
ui-6d5bb7b9c8-ghi56   1/1     Running   0          12s
ui-6d5bb7b9c8-arx97   1/1     Running   0          10s
ui-6d5bb7b9c8-uiv85   1/1     Running   0          10s
```

:::info
Kubernetesは、高可用性のためにこれらのPodを利用可能なワーカーノード全体に自動的に分散します。
:::

3つのレプリカにスケールダウンします：
```bash
$ kubectl scale deployment -n ui ui --replicas=3
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-abc12   1/1     Running   0          2m
ui-6d5bb7b9c8-def34   1/1     Running   0          12s
ui-6d5bb7b9c8-ghi56   1/1     Running   0          12s
```

### ローリング更新とロールバック
イメージバージョンを変更することでDeploymentを更新できます：
```bash
$ kubectl set image deployment/ui ui=public.ecr.aws/aws-containers/retail-store-sample-ui:v2 -n ui
$ kubectl get pods -n ui
NAME                  READY   STATUS         RESTARTS   AGE
ui-5989474687-5gcbt   1/1     Running        0          13m
ui-5989474687-dhk6q   1/1     Running        0          14s
ui-5989474687-dw8x8   1/1     Running        0          14s
ui-7c65b44b7c-znm9c   0/1     ErrImagePull   0          7s
```
> 新しいPodが作成されましたが、ステータスが`ErrImagePull`になっています。

それでは変更をロールバックしましょう：
```bash
$ kubectl rollout undo deployment/ui -n ui
$ kubectl get pods -n ui
NAME                  READY   STATUS         RESTARTS   AGE
ui-5989474687-5gcbt   1/1     Running        0          13m
ui-5989474687-dhk6q   1/1     Running        0          14s
ui-5989474687-dw8x8   1/1     Running        0          14s
```

ローリング更新により、ダウンタイムなしでアプリケーションを段階的に更新でき、Kubernetesは新しいPodが希望する状態と一致することを保証します。
無効なイメージなど問題が発生した場合は、以前の動作しているバージョンに安全にロールバックでき、アプリケーションの可用性を維持し、安定性を保つことができます。

これは、Deploymentがアプリケーションの更新を簡素化し、可用性を維持し、本番環境でのリスクを軽減する方法を示しています。

### 覚えておくべき重要なポイント

* Deploymentは複数の同一Podを自動的に管理します
* 本番環境では、Podを直接作成する代わりにDeploymentを使用します
* スケーリングは、レプリカ数を変更するだけで簡単にできます
* Pod名にはDeployment名とランダムなサフィックスが含まれます
* Deploymentは、WebアプリやAPIなどのステートレスアプリケーションに最適です

