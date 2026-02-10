---
title: "ベースライン PSS プロファイル"
sidebar_position: 62
tmdTranslationSourceHash: f15af985f33897c78496d07dceda1259
---

もしPodが要求できる権限を制限したい場合はどうすればよいでしょうか？例えば、前のセクションで「pss」Podに提供した`privileged`権限は危険で、攻撃者がコンテナ外のホストリソースにアクセスすることを許可してしまいます。

ベースラインPSSは、既知の権限昇格を防止する最小限の制限ポリシーです。`pss`名前空間にラベルを追加して有効にしましょう：

```kustomization
modules/security/pss-psa/baseline-namespace/namespace.yaml
Namespace/pss
```

Kustomizeを実行してこの変更を適用し、`pss`名前空間にラベルを追加します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/baseline-namespace
Warning: existing pods in namespace "pss" violate the new PodSecurity enforce level "baseline:latest"
Warning: pss-64c49f848b-gmrtt: privileged
namespace/pss configured
deployment.apps/pss unchanged
```

上記のように、`pss`DeploymentのPodがベースラインPSSに違反しているという警告がすでに表示されています。これは名前空間ラベル`pod-security.kubernetes.io/warn`によって提供されています。次に`pss` Deployment内のPodをリサイクルします：

```bash
$ kubectl -n pss delete pod --all
```

Podが実行されているかどうか確認しましょう：

```bash hook=no-pods
$ kubectl -n pss get pod
No resources found in pss namespace.
```

ご覧のように、名前空間ラベル`pod-security.kubernetes.io/enforce`によってPodが実行されていませんが、すぐにその理由はわかりません。独立して使用された場合、PSAモードには異なるレスポンスがあり、それぞれ異なるユーザー体験をもたらします。enforceモードは、それぞれのPod仕様が構成されたPSSプロファイルに違反している場合、Podの作成を防止します。ただし、このモードでは、DeploymentなどのPodを作成する非Pod Kubernetesオブジェクトは、そのPod仕様が適用されたPSSプロファイルに違反していても、クラスターに適用されることを妨げられません。この場合、DeploymentはPodの適用が妨げられている間も適用されます。

以下のコマンドを実行して、Deploymentリソースを検査し、ステータス状態を確認します：

```bash
$ kubectl get deployment -n pss pss -o yaml | yq '.status'
- lastTransitionTime: "2022-11-24T04:49:56Z"
  lastUpdateTime: "2022-11-24T05:10:41Z"
  message: ReplicaSet "pss-7445d46757" has successfully progressed.
  reason: NewReplicaSetAvailable
  status: "True"
  type: Progressing
- lastTransitionTime: "2022-11-24T05:10:49Z"
  lastUpdateTime: "2022-11-24T05:10:49Z"
  message: 'pods "pss-67d5fc995b-8r9t2" is forbidden: violates PodSecurity "baseline:latest": privileged (container "pss" must not set securityContext.privileged=true)'
  reason: FailedCreate
  status: "True"
  type: ReplicaFailure
- lastTransitionTime: "2022-11-24T05:10:56Z"
  lastUpdateTime: "2022-11-24T05:10:56Z"
  message: Deployment does not have minimum availability.
  reason: MinimumReplicasUnavailable
  status: "False"
  type: Available
```

一部のシナリオでは、正常に適用されたDeploymentオブジェクトが失敗したPod作成を反映していることを示す即時の指示はありません。違反しているPod仕様ではPodは作成されません。`kubectl get deploy -o yaml ...`でDeploymentリソースを検査すると、上記のテストで見られたように、失敗したPod(s)の`.status.conditions`要素からのメッセージが公開されます。

auditモードとwarnモードの両方のPSAでは、Pod制限は違反するPodの作成や起動を防止しません。ただし、これらのモードでは、APIサーバー監査ログイベントの監査注釈とAPIサーバークライアント（例：kubectl）への警告がそれぞれトリガーされます。これはPodだけでなく、PSS違反のあるPod仕様を含むPodを作成するオブジェクトでも発生します。

それでは、`privileged`フラグを削除して`pss` Deploymentを修正し、実行できるようにしましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/baseline-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

今回は警告を受け取らなかったので、Podが実行されているかどうかを確認し、`root`ユーザーとして実行されていないことを検証できます：

```bash
$ kubectl -n pss get pod
NAME                      READY   STATUS    RESTARTS   AGE
pss-864479dc44-d9p79      1/1     Running   0          15s

$ kubectl -n pss exec $(kubectl -n pss get pods -o name) -- whoami
appuser
```

`privileged`モードで実行されていたPodを修正したため、現在はベースラインプロファイルの下で実行が許可されています。
