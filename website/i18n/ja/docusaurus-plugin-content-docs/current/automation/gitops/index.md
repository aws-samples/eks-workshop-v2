---
title: "GitOps"
sidebar_position: 2
weight: 20
tmdTranslationSourceHash: bffd2f294faa49e347acd006bd1b4256
---

企業は迅速に進みたいと考えています。より頻繁に、より確実に、そして可能であればより少ないオーバーヘッドでデプロイする必要があります。GitOpsは、開発者がKubernetesで実行されている複雑なアプリケーションとインフラストラクチャを管理および更新するための迅速で安全な方法です。

GitOpsは、クラウドネイティブアプリケーションのインフラストラクチャとデプロイメントの両方を管理するための運用およびアプリケーションデプロイメントワークフローとベストプラクティスのセットです。この投稿は二つの部分に分かれています。最初の部分では、GitOpsの歴史と、その仕組みやメリットについて説明します。二つ目の部分では、FluxをAmazon Elastic Kubernetes Service（Amazon EKS）に使用して継続的デプロイメントパイプラインを設定する方法を説明するハンズオンチュートリアルで、自分自身で試すことができます。

GitOpsとは何でしょうか？Weaveworks CEOのAlexis Richardsonによって命名されたGitOpsは、Kubernetesおよびその他のクラウドネイティブテクノロジーの運用モデルです。クラスタとアプリケーションのデプロイメント、管理、監視を統合するベストプラクティスのセットを提供します。別の言い方をすれば、アプリケーション管理のための開発者エクスペリエンスへの道です。エンドツーエンドのCIおよびCDパイプラインとGitワークフローが運用と開発の両方に適用されます。

GitOpsセクションのビデオウォークスルーを、モジュールメンテナの一人であるCarlos Santana（AWS）とともにご覧ください：

<ReactPlayer controls src="https://www.youtube-nocookie.com/embed/dONzzCc0oHo" width={640} height={360} /> <br />

