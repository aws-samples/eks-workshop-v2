---
title: "メトリクスサーバー"
sidebar_position: 5
kiteTranslationSourceHash: 291842eaf4567d2355f1a79511b3836c
---

Kubernetes Metrics Serverはクラスター内のリソース使用データのアグリゲーターであり、Amazon EKSクラスターではデフォルトでデプロイされていません。詳細については、GitHubの[Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)をご覧ください。Metrics Serverは、Horizontal Pod AutoscalerやKubernetes Dashboardなど、他のKubernetesアドオンによって一般的に使用されています。詳細については、Kubernetesドキュメントの[リソースメトリクスパイプライン](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)をご覧ください。

Metrics Serverは、クラスター作成時にEKSコミュニティアドオンとして私たちのクラスターにデプロイされました：

```bash
$ kubectl -n kube-system get pod -l app.kubernetes.io/name=metrics-server
```

HPAがそのスケーリング動作を駆動するために使用するメトリクスを表示するには、`kubectl top`コマンドを使用します。例えば、このコマンドは私たちのクラスター内のノードのリソース使用率を表示します：

```bash
$ kubectl top node
```

また、Podのリソース使用率も取得できます。例えば：

```bash
$ kubectl top pod -l app.kubernetes.io/created-by=eks-workshop -A
```

HPAがPodをスケールするのを見ながら、これらのクエリを引き続き使用して何が起きているかを理解することができます。

