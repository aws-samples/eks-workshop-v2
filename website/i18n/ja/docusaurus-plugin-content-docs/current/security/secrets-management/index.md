---
title: "シークレット管理"
sidebar_position: 40
tmdTranslationSourceHash: 597d45e341c83e4eb22c3b224aaa55a2
---

[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)は、クラスターオペレーターがパスワード、OAuthトークン、sshキーなどの機密情報のデプロイを管理するのに役立つリソースです。これらのシークレットは、Podのコンテナにデータボリュームとしてマウントするか、環境変数として公開することができ、Podのデプロイと、Pod内のコンテナ化されたアプリケーションが必要とする機密データの管理を切り離すことができます。

DevOpsチームがさまざまなKubernetesリソースのYAMLマニフェストを管理し、Gitリポジトリを使用してバージョン管理することが一般的な慣行となっています。これにより、GitリポジトリをGitOpsワークフローと統合して、EKSクラスターにこのようなリソースの継続的な配信を行うことができます。
Kubernetesはシークレット内の機密データを単にbase64エンコーディングを使用して難読化しますが、そのようなファイルをGitリポジトリに保存することは、base64エンコードされたデータは簡単にデコードできるため、非常に安全ではありません。これにより、クラスター外部でKubernetes Secretsのためのマニフェストを管理することが難しくなります。

シークレット管理にはいくつかの異なるアプローチを使用できますが、このシークレット管理の章では、[Sealed Secrets for Kubernetes](https://github.com/bitnami-labs/sealed-secrets)と[AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)という2つのアプローチについて説明します。
