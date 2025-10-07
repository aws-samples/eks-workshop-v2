---
title: "アプリケーションのデプロイ"
sidebar_position: 15
kiteTranslationSourceHash: adf046743d7e3a4089ea63df04395056
---

クラスターにFluxを正常にブートストラップしたので、アプリケーションをデプロイできるようになりました。GitOpsベースのアプリケーションデリバリーと他の方法との違いを示すために、現在`kubectl apply -k`アプローチを使用しているサンプルアプリケーションのUIコンポーネントを新しいFluxデプロイメントアプローチに移行します。

まず、既存のUIコンポーネントを削除して置き換えましょう：

```bash
$ kubectl delete namespace ui
```

次に、前のセクションでFluxをブートストラップするために使用したリポジトリをクローンします：

```bash hook=clone
$ git clone ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/flux.git
```

次に、「apps」ディレクトリを作成してFluxリポジトリの構築を始めましょう。このディレクトリは、各アプリケーションコンポーネントのサブディレクトリを含むように設計されています：

```bash
$ mkdir ~/environment/flux/apps
```

次に、Fluxにそのディレクトリについて知らせるkustomizationを作成します：

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps.yaml" paths="metadata.name,spec.interval,spec.path"}

1. kustomizationに識別しやすい名前を付けます
2. Fluxに1分ごとにポーリングするように指示します
3. Gitリポジトリ内の`apps`パスを使用します

このファイルをGitリポジトリディレクトリにコピーします：

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps.yaml \
  ~/environment/flux/apps.yaml
```

アプリケーションコンポーネントは[Amazon ECR Public](https://gallery.ecr.aws/)に公開されているHelmチャートを使用してインストールします。

FluxにHelmチャートのソースを伝えるためのHelmRepositoryリソースを作成しましょう：

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/repository.yaml" paths="spec.url,spec.type,spec.interval"}

1. HelmリポジトリのURL
2. ECR PublicはHelmチャートをOCIアーティファクトとしてホストしています
3. 5分ごとに更新をチェックします

このファイルをGitリポジトリディレクトリにコピーします：

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/repository.yaml \
  ~/environment/flux/apps/repository.yaml
```

最後に、FluxにUIコンポーネントのHelmチャートをインストールするように指示します：

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/ui/helm.yaml" paths="metadata.name,spec.chart,spec.install.createNamespace,spec.values"}

1. HelmReleaseリソースの名前
2. 上記で指定したHelmリポジトリを参照するチャートの名前とバージョン
3. 名前空間が存在しない場合は作成します
4. この場合はイングレスを有効にするなど、`values`を使用してチャートを構成します

適切なファイルをGitリポジトリディレクトリにコピーします：

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/ui \
  ~/environment/flux/apps
```

Gitディレクトリは次のようになっているはずです。`tree ~/environment/flux`を実行して確認できます：

```text
.
├── apps
│   ├── repository.yaml
│   └── ui
│       ├── helm.yaml
│       └── kustomization.yaml
├── apps.yaml
└── flux-system
    ├── gotk-components.yaml
    ├── gotk-sync.yaml
    └── kustomization.yaml


3 directories, 7 files
```

最後に、構成をGitにプッシュします：

```bash
$ git -C ~/environment/flux add .
$ git -C ~/environment/flux commit -am "Adding the UI service"
$ git -C ~/environment/flux push origin main
```

Fluxがギットの変更に気づいて調整するまでに時間がかかります。Flux CLIを使用して、新しい`apps` kustomizationが表示されるのを監視できます：

```bash test=false
$ flux get kustomization --watch --timeout=10m
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:f39f67e   False        True    Applied revision: main@sha1:f39f67e
apps           main@sha1:f39f67e   False        True    Applied revision: main@sha1:f39f67e
```

また、Fluxに手動で調整をトリガーすることもできます：

```bash wait=30 hook=flux-deployment
$ flux reconcile source git flux-system -n flux-system
```

上記のように`apps`が表示されたら、`Ctrl+C`を使用してコマンドを閉じます。これで、UIサービスに関連するすべてのリソースが再度デプロイされているはずです。確認するには、次のコマンドを実行します：

```bash
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           5m
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-54ff78779b-qnrrc   1/1     Running   0          5m
```

Ingressリソースからのアドレスを取得します：

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

ロードバランサーのプロビジョニングが完了するまで待つには、このコマンドを実行します：

```bash timeout=300
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

Webブラウザからアクセスしてください。Webストアからのインタフェースが表示され、ユーザーとしてサイト内を移動できます。

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
