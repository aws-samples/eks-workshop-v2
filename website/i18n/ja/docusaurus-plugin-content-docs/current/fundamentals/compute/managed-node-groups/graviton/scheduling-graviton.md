---
title: Gravitonでポッドを実行する
sidebar_position: 20
kiteTranslationSourceHash: 375c541b385540f699ead3b7a4a1bf03
---

Gravitonノードグループをtaintで設定したので、このアプリケーションを活用するように設定する必要があります。そのために、`ui`マイクロサービスをGravitonベースのマネージドノードグループの一部であるノードにのみデプロイするようにアプリケーションを構成します。

変更を行う前に、現在のUIポッドの構成を確認しましょう。これらのポッドは`ui`という名前の関連デプロイメントによって制御されていることに留意してください。

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

予想通り、アプリケーションはtaintされていないノードで正常に実行されています。関連するポッドは`Running`ステータスであり、カスタムtolerationが設定されていないことを確認できます。Kubernetesは、あなたやコントローラーが明示的にこれらのtolerationを設定しない限り、`node.kubernetes.io/not-ready`と`node.kubernetes.io/unreachable`のtolerationを`tolerationSeconds=300`で自動的に追加することに注意してください。これらの自動的に追加されるtolerationは、これらの問題のいずれかが検出されてから5分間、ポッドがノードにバインドされたままであることを意味します。

taintされたマネージドノードグループにポッドをバインドするように`ui`デプロイメントを更新しましょう。`nodeSelector`で使用できるように、taintされたマネージドノードグループに`tainted=yes`というラベルを事前に設定しました。以下の`Kustomize`パッチは、このセットアップを有効にするためにデプロイメント構成に必要な変更を説明しています：

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```
上記のマニフェストでは、`nodeSelector`は`kubernetes.io/arch: arm64`というラベルを持つノードにのみポッドをスケジュールするように指定しています。この`nodeSelector`は、UIポッドがARM64アーキテクチャノード（Gravitonノード）でのみ実行されるように効果的に制限します。

Kustomizeの変更を適用するには、次のコマンドを実行します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

最近行った変更で、UIデプロイメントのロールアウトステータスを確認しましょう：

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

`ui`デプロイメントのデフォルトの`RollingUpdate`戦略では、K8sデプロイメントは古いものを終了する前に新しく作成されたポッドが`Ready`状態になるのを待ちます。デプロイメントのロールアウトが詰まっているようなので、さらに調査しましょう：

```bash hook=pending-pod
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

`ui`名前空間の個々のポッドを調査すると、1つのポッドが`Pending`状態にあることがわかります。`Pending`ポッドの詳細をさらに調べると、発生した問題に関する情報が得られます。

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

私たちの変更は`Pending`ポッドの新しい構成に反映されています。`tainted=yes`ラベルを持つ任意のノードにポッドをピン留めしましたが、これにより新しい問題が発生しました。ポッドをスケジュールできません（`PodScheduled False`）。より有用な説明は`events`の下にあります：

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

これを修正するには、tolerationを追加する必要があります。デプロイメントと関連するポッドが`frontend: true`のtaintを許容できるようにしましょう。必要な変更を行うために、以下の`kustomize`パッチを使用できます：

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```
このYAMLは前の構成に基づいてtolerationを追加しています。`tolerations`セクションは、以下のように説明されている`frontend` taintを持つノードにポッドをスケジュールすることを許可します：
- `key: "frontend"`は許容するtaintキーを指定します。
- `operator: "Exists"`は、その値に関係なくポッドがtaintを許容することを意味します。
- `effect: "NoExecute"`はtaintの効果と一致し、このtaintを持つノードでポッドが実行できるようにします。

nodeSelectorは同じままで、ポッドがARM64アーキテクチャノードでのみ実行されるようにします。Kustomizeの変更を適用するには、次のコマンドを実行します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

UIポッドを確認すると、構成に指定されたtoleration（`frontend=true:NoExecute`）が含まれ、対応するtaintを持つノードに正常にスケジュールされていることがわかります。検証には次のコマンドを使用できます：

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

ご覧のように、`ui`ポッドは現在Gravitonベースのノードグループで実行されています。さらに、`kubectl describe node`コマンドでTaintsが表示され、`kubectl describe pod`コマンドで一致するTolerationsが表示されます。

IntelとARMの両方のプロセッサで実行できる`ui`アプリケーションを、前のステップで作成した新しいGravitonベースのマネージドノードグループで実行するようにスケジュールすることに成功しました。TaintsとTolerationsは、ポッドがノードにどのようにスケジュールされるかを設定するための強力なツールであり、Graviton/GPUが強化されたノード、またはマルチテナントKubernetesクラスタに使用できます。
