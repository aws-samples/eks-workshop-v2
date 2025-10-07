---
title: Graviton でポッドを実行する
sidebar_position: 20
kiteTranslationSourceHash: 375c541b385540f699ead3b7a4a1bf03
---

Graviton ノードグループに taint を適用したので、この変更を活用するようにアプリケーションを設定する必要があります。そのために、`ui` マイクロサービスを Graviton ベースのマネージドノードグループの一部であるノードにのみデプロイするようにアプリケーションを設定しましょう。

変更を加える前に、現在の UI ポッドの構成を確認しましょう。これらのポッドは `ui` という名前の関連するデプロイメントによって制御されていることに注意してください。

```bash
$ kubectl describe pod --namespace ui --selector app.kubernetes.io/name=ui
Name:             ui-7bdbf967f9-qzh7f
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-11-43.us-west-2.compute.internal/10.42.11.43
Start Time:       Wed, 09 Nov 2022 16:40:32 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=7bdbf967f9
Status:           Running
[....]
Controlled By:  ReplicaSet/ui-7bdbf967f9
Containers:
[...]
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```

予想通り、アプリケーションは taint が適用されていないノード上で正常に実行されています。関連するポッドは `Running` ステータスであり、カスタムの許容（tolerations）が設定されていないことを確認できます。Kubernetes は、明示的に設定していない限り、`node.kubernetes.io/not-ready` と `node.kubernetes.io/unreachable` に対する許容を `tolerationSeconds=300` で自動的に追加することに注意してください。これらの自動的に追加される許容により、これらの問題のいずれかが検出された後も、ポッドはノードにバインドされたまま 5 分間維持されます。

taint が適用されたマネージドノードグループにポッドをバインドするために、`ui` デプロイメントを更新しましょう。マネージドノードグループには `tainted=yes` というラベルがあらかじめ設定されており、これを `nodeSelector` で使用することができます。以下の `Kustomize` パッチは、この設定を有効にするためにデプロイメント構成に必要な変更を記述しています：

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```
上記のマニフェストでは、`nodeSelector` が `kubernetes.io/arch: arm64` ラベルを持つノードにのみポッドをスケジュールするよう指定しています。この `nodeSelector` により、UI ポッドは ARM64 アーキテクチャのノード（Graviton ノード）でのみ実行されるように効果的に制限されます。

Kustomize の変更を適用するには、次のコマンドを実行します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

最近行った変更で、UI デプロイメントのロールアウトステータスを確認しましょう：

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

`ui` デプロイメントのデフォルトの `RollingUpdate` 戦略により、K8s デプロイメントは古いポッドを終了する前に、新しく作成されたポッドが `Ready` 状態になるのを待ちます。デプロイメントのロールアウトが停止しているようなので、さらに調査しましょう：

```bash hook=pending-pod
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

`ui` 名前空間の個々のポッドを調査すると、1つのポッドが `Pending` 状態であることがわかります。`Pending` ポッドの詳細をさらに調べると、発生している問題に関する情報が得られます。

```bash
$ podname=$(kubectl get pod --namespace ui --field-selector=status.phase=Pending -o json | \
                jq -r '.items[0].metadata.name') && \
                kubectl describe pod $podname -n ui
Name:           ui-659df48c56-z496x
Namespace:      ui
[...]
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  19s   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

私たちの変更は `Pending` ポッドの新しい設定に反映されています。ポッドを `tainted=yes` ラベルを持つノードに固定しましたが、これによりポッドがスケジュールできない（`PodScheduled False`）という新しい問題が発生しました。`events` の下でより有用な説明が見つかります：

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

これを修正するには、許容（toleration）を追加する必要があります。デプロイメントと関連するポッドが `frontend: true` の taint を許容できるようにしましょう。以下の `kustomize` パッチを使用して、必要な変更を加えることができます：

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```
この YAML は、許容を追加することで以前の構成を拡張しています。`tolerations` セクションでは、以下のように説明されている `frontend` taint を持つノード上でポッドがスケジュールされることを可能にしています：
- `key: "frontend"` は許容する taint キーを指定します。
- `operator: "Exists"` はポッドが値に関係なく taint を許容することを意味します。
- `effect: "NoExecute"` は taint の効果と一致し、ポッドがこの taint を持つノード上で実行できるようにします。

nodeSelector は同じままで、ポッドが ARM64 アーキテクチャノードでのみ実行されるようにします。Kustomize の変更を適用するには、次のコマンドを実行します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

UI ポッドを確認すると、構成に指定した許容（`frontend=true:NoExecute`）が含まれており、対応する taint を持つノード上で正常にスケジュールされていることがわかります。以下のコマンドで検証できます：

```bash
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6c5c9f6b5f-7jxp8   1/1     Running   0          29s
```

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:         ui-6c5c9f6b5f-7jxp8
Namespace:    ui
Priority:     0
Node:         ip-10-42-10-138.us-west-2.compute.internal/10.42.10.138
Start Time:   Fri, 11 Nov 2022 13:00:36 +0000
Labels:       app.kubernetes.io/component=service
              app.kubernetes.io/created-by=eks-workshop
              app.kubernetes.io/instance=ui
              app.kubernetes.io/name=ui
              pod-template-hash=6c5c9f6b5f
Annotations:  kubernetes.io/psp: eks.privileged
              prometheus.io/path: /actuator/prometheus
              prometheus.io/port: 8080
              prometheus.io/scrape: true
Status:       Running
IP:           10.42.10.225
IPs:
  IP:           10.42.10.225
Controlled By:  ReplicaSet/ui-6c5c9f6b5f
Containers:
  [...]
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
[...]
QoS Class:                   Burstable
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 frontend:NoExecute op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
[...]
```

```bash
$ kubectl describe node --selector kubernetes.io/arch=arm64
Name:               ip-10-42-10-138.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-03e8f91597dcf297b
                    kubernetes.io/arch=arm64
                    kubernetes.io/hostname=ip-10-42-10-138.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=t4g.medium
[...]
Taints:             frontend=true:NoExecute
Unschedulable:      false
[...]
```

ご覧のとおり、`ui` ポッドは現在 Graviton ベースのノードグループ上で実行されています。さらに、`kubectl describe node` コマンドでは Taints が、`kubectl describe pod` コマンドでは対応する Tolerations が確認できます。

これで、Intel と ARM の両方のプロセッサで実行できる `ui` アプリケーションを、前のステップで作成した新しい Graviton ベースのマネージドノードグループ上で実行するようにスケジュールすることに成功しました。Taints と Tolerations は、Graviton/GPU 強化ノードやマルチテナント Kubernetes クラスタなど、ポッドがノードにどのようにスケジュールされるかを設定するための強力なツールです。
