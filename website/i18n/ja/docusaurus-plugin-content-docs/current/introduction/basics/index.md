---
title: Kubernetes の基礎
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "アーキテクチャ、Helm、Kustomize を含む Kubernetes の基本的な概念を学びます。"
tmdTranslationSourceHash: d1fe31f35d924b01aa73fcb5e1885218
---

# Kubernetes の概念

ハンズオンラボに入る前に、**Kubernetes がどのように機能するか**、そして**このワークショップを通じて使用するツール**を理解することが重要です。このセクションでは、EKS 学習の基礎となるコアアーキテクチャ、主要コンポーネント、デプロイメントツールを紹介します。

:::tip 始める前に
このセクションの環境を準備します:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics
```

:::

## Kubernetes アーキテクチャ概要

Kubernetes は **コントロールプレーンとワーカーノードのアーキテクチャ**に従っており、**コントロールプレーン**がクラスターを管理し、**ワーカーノード**がワークロードを実行します。

![Kubernetes Cluster Architecture](https://kubernetes.io/images/docs/kubernetes-cluster-architecture.svg)
*図: 簡略化された Kubernetes クラスターアーキテクチャ*

### コントロールプレーンコンポーネント

コントロールプレーンはクラスターに関するグローバルな決定を行い、システムの望ましい状態を保証します。

- **API Server** — Kubernetes のフロントエンドとして機能し、ユーザーとコンポーネントに Kubernetes API を公開します。
- **etcd** — すべてのクラスターデータを保持する高可用性のキーバリューストアです。
- **Scheduler** — リソースの可用性と制約に基づいて、Pod をノードに割り当てます。
- **Controller Manager** — クラスターの健全性を維持し、実際の状態と望ましい状態を調整するバックグラウンドプロセス（コントローラー）を実行します。

### ワーカーノードコンポーネント

各ノードは Pod をホストし管理するために必要なコンポーネントを実行します。

- **kubelet** — コントロールプレーンと通信し、コンテナが期待どおりに実行されていることを確認します。
- **Container Runtime** — コンテナを実行します（例: containerd、CRI-O）。
- **kube-proxy** — ネットワークルールを維持し、Pod とサービス間の通信を管理します。

---

## Amazon EKS アーキテクチャ

**Amazon Elastic Kubernetes Service (EKS)** は、クラスター運用を簡素化するマネージド Kubernetes サービスです。
コントロールプレーンの管理、アップグレード、高可用性を担当するため、ワークロードに集中できます。

EKS では以下が可能です:
- 運用オーバーヘッドを削減して**アプリケーションをより迅速にデプロイ**
- 変化するワークロードに対応するために**シームレスにスケール**
- AWS IAM とマネージドアップデートを使用して**セキュリティを強化**
- **コンピューティングモデルを選択** — 従来の EC2 ノードまたは EKS Auto Mode によるサーバーレス

### 責任共有モデル

Amazon EKS では:
- **AWS がコントロールプレーンを管理** — API Server、etcd、Scheduler、コントローラーを含みます。
- **お客様がワーカーノードを管理** — アプリケーションが実行される EC2、Fargate、またはハイブリッドオプション。
- **AWS サービスがネイティブに統合** — ロードバランサー、IAM ロール、VPC ネットワーキング、ストレージを含みます。

![Amazon EKS Architecture](https://docs.aws.amazon.com/images/eks/latest/userguide/images/whatis.png)
*図: Amazon EKS アーキテクチャと AWS サービスとの統合*

## 覚えておくべき重要なポイント

Kubernetes アーキテクチャを理解することは、効果的なクラスター管理とトラブルシューティングに不可欠です:

### コントロールプレーン vs ワーカーノード
- **コントロールプレーン**コンポーネント（API Server、etcd、Scheduler、Controller Manager）は、クラスター全体の決定と状態管理を処理します
- **ワーカーノード**（kubelet、Container Runtime、kube-proxy）は、アプリケーションの実行とネットワーキングに重点を置いています
- この分離により、スケーラブルで回復力のあるクラスター運用が可能になります

### EKS の利点
- **運用負荷の軽減** — AWS がコントロールプレーンの複雑性、パッチ適用、高可用性を管理します
- **ネイティブな AWS 統合** — VPC、IAM、Load Balancers、その他の AWS サービスとのシームレスな接続
- **柔軟なコンピューティングオプション** — ワークロードのニーズに基づいて EC2、Fargate、または Auto Mode から選択

### 設計原則
- **宣言的な設定** — 望ましい状態を定義し、Kubernetes コントローラーがそれを達成するために動作します
- **API 駆動** — すべてのインタラクションは一貫性と監査可能性のために Kubernetes API を経由します
- **拡張可能** — カスタムリソースとコントローラーにより Kubernetes の機能を拡張できます

これらのアーキテクチャの概念は、アプリケーションのデプロイ、Helm と Kustomize による設定管理、高度なクラスター機能の実装を進めていく上で不可欠です。

