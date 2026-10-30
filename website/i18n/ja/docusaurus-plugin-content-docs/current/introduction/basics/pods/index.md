---
title: Pod
sidebar_position: 20
tmdTranslationSourceHash: c90463a70c1082cf45b0350bbca20a02
---

# Pod

**Pod**はKubernetesにおける最小のデプロイ可能な単位です。Podは、ストレージ、ネットワーク、および実行方法の設定を共有する1つ以上のコンテナを表します。

Podが提供するもの:
- **コンテナのグループ化:** 通常、Podは単一のコンテナを実行しますが、データを共有したりlocalhost経由で通信する必要がある密結合な複数のコンテナを含めることができます。
- **共有ネットワーク:** Pod内のすべてのコンテナは同じIPアドレスを共有します
- **共有ストレージ:** コンテナはPod内でボリュームを共有できます
- **ライフサイクル管理:** Pod内のコンテナは一緒に生き、一緒に終了します
- **一時的な性質:** Podは作成、破棄、再作成が可能です

このラボでは、シンプルなサンプルPodを作成し、そのプロパティを調べることでPodについて学習します。

### Podの作成

Podがどのように機能するかを理解するために、シンプルなPodを作成しましょう。このマニフェストは、小売ストアのUIコンテナを実行するシンプルなPodを定義しています。

::yaml{file="manifests/modules/introduction/basics/pods/ui-pod.yaml" paths="kind,metadata.name,metadata.namespace,spec.containers,spec.containers.0.name,spec.containers.0.image,spec.containers.0.ports,spec.containers.0.env,spec.containers.0.resources" title="ui-pod.yaml"}

1. `kind: Pod`: 作成するリソースのタイプをKubernetesに指示します
2. `metadata.name`: Namespace内でこのPodを一意に識別する名前
3. `metadata.namespace`: Podが属するNamespace（ui Namespace）
4. `spec.containers`: Pod内で実行するコンテナを定義する配列
5. `spec.containers.0.name`: 最初のコンテナの名前（ui）
6. `spec.containers.0.image`: ECR PublicレジストリのコンテナImage
7. `spec.containers.0.ports`: コンテナが公開するネットワークポート
8. `spec.containers.0.env`: コンテナの環境変数
9. `spec.containers.0.resources`: CPUとメモリの割り当て設定

Pod設定を適用します:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
```

Kubernetesは`ui` Namespace内にPodを作成し、コンテナImageのプルを開始します。

Podの準備が完了するまで待ちます:
```bash
$ kubectl wait --for=condition=Ready --timeout=60s -n ui pod/ui-pod
```

### Podの調査

次に、作成したPodを確認しましょう:

```bash
$ kubectl get pods -n ui
NAME     READY   STATUS    RESTARTS   AGE
ui-pod   1/1     Running   0          30s
```

Podの詳細情報を取得します:
```bash
$ kubectl describe pod -n ui ui-pod
Name:             ui-pod
Namespace:        ui
Priority:         0
Service Account:  default
Node:             ip-10-42-144-0.us-west-2.compute.internal/10.42.144.0
Start Time:       Sun, 05 Oct 2025 19:28:02 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/name=ui
Annotations:      <none>
Status:           Running
IP:               10.42.146.177
IPs:
  IP:  10.42.146.177
Containers:
  ui:
    Container ID:   containerd://01709a8abac99ce46842dda128752a68e828a485ee47f2094549fc00f9d71953
    Image:          public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Image ID:       public.ecr.aws/aws-containers/retail-store-sample-ui@sha256:63a531dd3716cf9f6a3c7b54d65c39ce4de43cb23a613ac2933f2cb38aff86d7
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 05 Oct 2025 19:28:03 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      memory:  1536Mi
    Requests:
      cpu:     250m
      memory:  1536Mi
    Environment:
      JAVA_OPTS:  -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-68xdw (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-68xdw:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  10s   default-scheduler  Successfully assigned ui/ui-pod to ip-10-42-144-0.us-west-2.compute.internal
  Normal  Pulled     10s   kubelet            Container image "public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1" already present on machine
  Normal  Created    10s   kubelet            Created container: ui
  Normal  Started    10s   kubelet            Started container ui
```

これには以下が表示されます:
- **コンテナの仕様** - Image、ポート、環境変数
- **リソース使用量** - CPUとメモリのリクエスト/制限
- **イベント** - Pod作成中に発生したこと
- **ステータス** - 現在の状態とヘルス

Podのログを表示します:
```bash
$ kubectl logs -n ui ui-pod
Picked up JAVA_TOOL_OPTIONS: 

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-10-05T19:28:06.600Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 21.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2025-10-05T19:28:06.658Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : The following 1 profile is active: "prod"
2025-10-05T19:28:10.268Z  INFO 1 --- [           main] i.o.i.s.a.OpenTelemetryAutoConfiguration : OpenTelemetry Spring Boot starter has been disabled

2025-10-05T19:28:11.712Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 4 endpoints beneath base path '/actuator'
2025-10-05T19:28:14.045Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080 (http)
2025-10-05T19:28:14.075Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 8.505 seconds (process running for 10.444)
```

> UIコンテナが起動しているのが確認できます。

Pod内でコマンドを実行します:
```bash hook=ready
$ kubectl exec -n ui ui-pod -- curl -s localhost:8080/actuator/health
{"status":"UP","groups":["liveness","readiness"]}
```
これによりアプリケーションのステータスが返されます。

### Podへのアクセス

ポートフォワーディングを使用して、ローカルマシンからPodにアクセスできます:
```bash test=false
$ kubectl port-forward -n ui ui-pod 8080:8080
```

:::info
ポートフォワーディングは、ローカルポートをPod内のポートに一時的に接続し、ラップトップから直接アプリケーションにアクセスできるようにします。
:::

Workshop IDEでは、転送されたすべてのポートを表示するポップアップが表示されます。クリックしてブラウザでアプリケーションURLを開きます。

または、別のターミナルを開いてテストします:
```bash test=false
$ curl localhost:8080
```

ブラウザで、小売ストアアプリケーションのランディングページが表示されます。

`CTRL+C`を押して`port-forward`セッションを終了します。

### Podの削除

Podが不要になったら、`kubectl delete`コマンドを使用して削除できます。Podを削除する方法はいくつかあります:

**方法1: 名前で削除**
```bash
$ kubectl delete pod -n ui ui-pod
pod "ui-pod" deleted
```

**方法2: マニフェストファイルを使用して削除**
`ui-pod`を再作成してマニフェストファイルを使用して削除しましょう。
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
$ kubectl delete -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
pod "ui-pod" deleted
```

削除後、Podが消えたことを確認します:
```bash
$ kubectl get pods -n ui
No resources found in ui namespace.
```

:::warning
Podを直接削除すると、完全に消えます。Pod内のデータ（永続ボリュームに保存されていない限り）は失われます。本番環境では、Podは通常、必要に応じて自動的に再作成するDeploymentなどのコントローラーによって管理されます。
:::

### Podのライフサイクル

Podには、クラスター内の現在の状態を反映する明確に定義されたライフサイクルフェーズがあります。
- **Pending** - Podがスケジュールされ、コンテナが起動中です
- **Running** - 少なくとも1つのコンテナが実行中です
- **Succeeded** - すべてのコンテナが正常に完了しました
- **Failed** - 少なくとも1つのコンテナが失敗しました
- **Unknown** - Podの状態を判別できません

Kubernetesコントローラーは継続的にPodの状態を監視し、目的のアプリケーションヘルスを維持するために（失敗したコンテナの再起動やPodの再作成などの）アクションを実行します。

## 覚えておくべき重要なポイント

* PodはKubernetesにおける最小のデプロイ可能な単位です
* 通常は1つのコンテナを含みますが、複数含むこともできます
* Pod内でネットワークとストレージを共有します
* Podは一時的なものです - 作成されたり削除されたりします
* 通常、Deploymentなどのより高レベルのコントローラーによって管理されます

:::info
実際のシナリオでは、Podを直接作成することはほとんどありません。代わりに、Deployment、ReplicaSet、JobなどのAPIリソースを使用して管理します。
:::
