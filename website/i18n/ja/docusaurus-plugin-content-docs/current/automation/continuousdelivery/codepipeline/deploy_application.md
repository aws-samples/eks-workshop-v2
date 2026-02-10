---
title: "アプリケーションのデプロイ"
sidebar_position: 30
tmdTranslationSourceHash: 48138a90920964475bfb4a0cd93f4fc2
---

アプリケーションをデプロイする前に、既存のUIコンポーネントを削除し、名前空間を再作成しましょう：

```bash
$ kubectl delete namespace ui
$ kubectl create namespace ui
```

次に、パイプラインを実行して、イメージをビルドし、EKSクラスターにデプロイしましょう。

```bash wait=20
$ git -C ~/environment/codepipeline add .
$ git -C ~/environment/codepipeline commit -am "Initial setup"
$ git -C ~/environment/codepipeline push --set-upstream origin main
```

CodePipelineがイメージをビルドし、すべての変更をEKSクラスターにデプロイするには3〜5分かかります。AWSコンソールでパイプラインの進行状況を監視するか、これらのコマンドを使用して完了するまで待つことができます：

```bash timeout=900
$ while [[ "$(aws codepipeline list-pipeline-executions --pipeline-name ${EKS_CLUSTER_NAME}-retail-store-cd --query 'pipelineExecutionSummaries[0].trigger.triggerType' --output text)" != "CloudWatchEvent" ]]; do echo "Waiting for pipeline to start ..."; sleep 10; done && echo "Pipeline started."
$ while [[ "$(aws codepipeline list-pipeline-executions --pipeline-name ${EKS_CLUSTER_NAME}-retail-store-cd --query 'pipelineExecutionSummaries[0].status' --output text)" != "Succeeded" ]]; do echo "Waiting for pipeline execution to finish ..."; sleep 10; done && echo "Pipeline execution successful."
```

完了すると、パイプラインのステージが成功したことが表示されます。

![パイプライン完了](/docs/automation/continuousdelivery/codepipeline/pipeline-complete.webp)

それでは、パイプラインによって行われた変更を確認しましょう。まず、ECRリポジトリを確認できます：

<ConsoleButton
  url="https://console.aws.amazon.com/ecr/private-registry/repositories"
  service="ecr"
  label="ECRコンソールを開く"
/>

リポジトリ `retail-store-sample-ui` を開き、プッシュされたイメージを確認します。

![イメージ 1](/docs/automation/continuousdelivery/codepipeline/ecr_image.webp)

また、クラスターにHelmリリースがインストールされていることも確認できます：

```bash hook=deployment
$ helm ls -n ui
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
ui      ui              1               2025-07-01 05:16:56.016555446 +0000 UTC deployed        retail-store-sample-ui-chart-0.8.5
```

カスタムイメージリポジトリとタグが使用されたことを確認するために、設定に使用された値を確認します：

```bash
$ helm get values -n ui ui
USER-SUPPLIED VALUES:
image:
  repository: 1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-store-sample-ui-sm7zww
  tag: e37f1e7932270d24d7bd7583d484dc2a
```

これにより、デプロイメントが作成されています：

```bash
$ kubectl get deployment -n ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           42s
```

ポッドはパイプラインでビルドされたイメージを使用しています：

```bash
$ kubectl get deployment -n ui ui -o json | jq -r '.spec.template.spec.containers[0].image'
1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-store-sample-ui-sm7zww:e37f1e7932270d24d7bd7583d484dc2a
```

また、`deploy_eks` アクションをクリックして、ログなどの詳細情報を表示することもできます：

![パイプラインデプロイ詳細](/docs/automation/continuousdelivery/codepipeline/pipeline-deploy-detail.webp)

これで、アプリケーションコンテナイメージをビルドし、Helmチャートを使用してEKSクラスターにデプロイするパイプラインを正常に作成しました。
