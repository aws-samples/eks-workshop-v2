---
title: "コントロールプレーン"
sidebar_position: 3
weight: 30
tmdTranslationSourceHash: 43a721c193e756f71a320dccfdefc13b
---

コントロールプレーンフレームワークを使用すると、標準のKubernetes CLI、`kubectl`を使用して、Kubernetesから直接AWSリソースを管理できます。これは、AWS管理サービスをKubernetesの[カスタムリソース定義（CRDs）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)としてモデル化し、それらの定義をクラスターに適用することで実現されます。つまり、開発者はコンテナからAWS管理サービスまで、アプリケーションアーキテクチャ全体を単一のYAMLマニフェストからモデル化できます。コントロールプレーンは、新しいアプリケーションの作成にかかる時間を短縮し、クラウドネイティブソリューションを望ましい状態に維持するのに役立つと予想されます。

コントロールプレーンの2つの人気のあるオープンソースプロジェクトは、[AWS Controllers for Kubernetes（ACK）](https://aws-controllers-k8s.github.io/community/)とCNCFインキュベーティングプロジェクト[Crossplane](https://www.crossplane.io/)です。どちらもAWSサービスをサポートしています。このワークショップモジュールはこの2つのプロジェクトに焦点を当てています。
