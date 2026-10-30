---
title: Gravitonでポッドを実行する
sidebar_position: 20
tmdTranslationSourceHash: '0410280636440a7890486a9e0df6fc16'
---

Graviton ノードグループに Taint を設定したので、この変更を活用するようにアプリケーションを構成する必要があります。そのために、`ui` マイクロサービスを Graviton ベースのマネージドノードグループに含まれるノードにのみデプロイするように構成しましょう。

変更を行う前に、UI の Pod の現在の構成を確認しましょう。これらの Pod は `ui` という名前の関連する Deployment によって制御されていることに留意してください。

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

予想どおり、アプリケーションは Taint されていないノードで正常に実行されています。関連する Pod は `Running` ステータスであり、カスタムの Toleration が設定されていないことを確認できます。Kubernetes は、ユーザーまたはコントローラーが明示的に設定しない限り、`node.kubernetes.io/not-ready` と `node.kubernetes.io/unreachable` の Toleration を `tolerationSeconds=300` で自動的に追加することに注意してください。これらの自動的に追加される Toleration により、これらの問題のいずれかが検出されてから 5 分間、Pod はノードにバインドされたままになります。

`ui` Deployment を更新して、その Pod を Taint されたマネージドノードグループにバインドしましょう。Graviton ベースのノードは `kubernetes.io/arch=arm64` ラベルで識別でき、これを `nodeSelector` で使用できます。以下の `Kustomize` パッチは、この設定を有効にするために Deployment の構成に必要な変更を示しています。

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```

上記のマニフェストでは、`nodeSelector` により、`kubernetes.io/arch: arm64` というラベルを持つノードにのみ Pod をスケジュールするように指定しています。この `nodeSelector` は、UI の Pod を ARM64 アーキテクチャのノード（Graviton ノード）でのみ実行するように効果的に制限します。

Kustomize の変更を適用するには、次のコマンドを実行します。

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

行った変更を踏まえて、UI Deployment のロールアウトステータスを確認しましょう。

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

`ui` Deployment のデフォルトの `RollingUpdate` ストラテジーでは、Kubernetes の Deployment は新しく作成された Pod が `Ready` 状態になるのを待ってから古い Pod を終了します。ロールアウトが停止しているようなので、さらに調査しましょう。

```bash hook=pending-pod
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

`ui` Namespace 内の個々の Pod を調べると、1 つの Pod が `Pending` 状態にあることがわかります。`Pending` の Pod の詳細をさらに掘り下げると、発生している問題に関する情報が得られます。

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

行った変更は、`Pending` の Pod の新しい構成に反映されています。Pod を `kubernetes.io/arch=arm64` ラベルを持つ任意のノードに固定しましたが、これにより Pod をスケジュールできないという新たな問題が発生しました（`PodScheduled False`）。より有用な説明は `events` に記載されています。

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

これを修正するには、Toleration を追加する必要があります。Deployment と関連する Pod が `frontend: true` の Taint を許容できるようにしましょう。必要な変更を行うために、以下の `kustomize` パッチを使用できます。

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```

この YAML は、前の構成に Toleration を追加したものです。`tolerations` セクションにより、以下で説明するように、`frontend` Taint を持つノードに Pod をスケジュールできるようになります。

- `key: "frontend"` は、許容する Taint のキーを指定します。
- `operator: "Exists"` は、値に関係なく Pod がその Taint を許容することを意味します。
- `effect: "NoExecute"` は Taint の effect と一致し、この Taint を持つノードで Pod を実行できるようにします。

nodeSelector は変更されず、Pod は引き続き ARM64 アーキテクチャのノードでのみ実行されます。Kustomize の変更を適用するには、次のコマンドを実行します。

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

UI の Pod を確認すると、構成に指定した Toleration（`frontend=true:NoExecute`）が含まれており、対応する Taint を持つノードに正常にスケジュールされていることがわかります。検証には次のコマンドを使用できます。

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

ご覧のとおり、`ui` Pod は現在 Graviton ベースのノードグループで実行されています。さらに、`kubectl describe node` コマンドでは Taints が、`kubectl describe pod` コマンドでは一致する Tolerations が確認できます。

Intel と ARM のどちらのプロセッサでも実行できる `ui` アプリケーションを、前のステップで作成した新しい Graviton ベースのマネージドノードグループで実行するようにスケジューリングできました。Taint と Toleration は、Graviton や GPU で強化されたノードの場合でも、マルチテナントの Kubernetes クラスターの場合でも、Pod がノードにどのようにスケジュールされるかを設定するための強力なツールです。
