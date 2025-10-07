---
title: "Gitリポジトリ"
sidebar_position: 10
kiteTranslationSourceHash: c62b494fcd4d8e73bd06482e73ffc5cd
---

:::note
CodePipelineは、AWS CodeConnectionsを通じてGitHubやGitLab、Bitbucketなどのソースをサポートしています。実際のアプリケーションでは、これらのソースを使用するべきです。しかし、このラボでは簡単にするためにS3をソースリポジトリとして使用します。
:::

このモジュールではS3をソースアクションとして使用し、[git-remote-s3](https://github.com/awslabs/git-remote-s3?tab=readme-ov-file#repo-as-s3-source-for-aws-codepipeline)ライブラリを使用して、Web IDE内の`git`を通じてそのバケットにデータを取り込みます。

リポジトリは以下のもので構成されます：

1. カスタムUIコンテナイメージを作成するためのDockerfile
2. コンポーネントをデプロイするためのHelmチャート
3. デプロイされるイメージをオーバーライドする`values.yaml`ファイル

```text
.
├── chart/
|   ├── templates/
|   ├── Chart.yaml
│   └── values.yaml
|── values.yaml
└── Dockerfile
```

このラボで使用するDockerfileは意図的に簡略化されています：

```file
manifests/modules/automation/continuousdelivery/codepipeline/repo/Dockerfile
```

リポジトリのルートにある`values.yaml`ファイルは、正しいコンテナイメージとタグを設定するだけの役割を持っています：

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/repo/values.yaml"}

`IMAGE_URL`と`IMAGE_REPOSITORY`環境変数は、後で見るようにパイプラインで設定されます。

まずはGitを設定しましょう：

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

次に、Gitリポジトリとして使用するディレクトリに各種ファイルをコピーします：

```bash timeout=120
$ mkdir -p ~/environment/codepipeline/chart
$ git -C ~/environment/codepipeline init -b main
$ git -C ~/environment/codepipeline remote add \
  origin s3+zip://${EKS_CLUSTER_NAME}-${AWS_ACCOUNT_ID}-retail-store-sample-ui/my-repo
$ cp -R ~/environment/eks-workshop/modules/automation/continuousdelivery/codepipeline/repo/* \
  ~/environment/codepipeline
$ helm pull oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart:1.2.1 \
  -d /tmp
$ tar zxf /tmp/retail-store-sample-ui-chart-1.2.1.tgz \
  -C ~/environment/codepipeline/chart --strip-components=1
```
