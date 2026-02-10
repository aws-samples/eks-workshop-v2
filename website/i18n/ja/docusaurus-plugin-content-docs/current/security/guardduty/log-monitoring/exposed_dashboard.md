---
title: "公開された Kubernetes ダッシュボード"
sidebar_position: 523
tmdTranslationSourceHash: bf5de5c93b37a21ed7af7bdbc6a9f938
---

この検出結果は、EKS Cluster のダッシュボードが Load Balancer サービスによってインターネットに公開されていることを通知します。公開されたダッシュボードは、クラスターの管理インターフェースをインターネットから公にアクセス可能にし、悪意のある行為者が存在する可能性のある認証とアクセス制御のギャップを悪用することを可能にします。

これをシミュレートするために、Kubernetes ダッシュボードコンポーネントをインストールする必要があります。[リリースノート](https://github.com/kubernetes/dashboard/releases/tag/v2.7.0)に基づいて、EKS Cluster vVAR::KUBERNETES_VERSION と互換性のあるダッシュボードの最新バージョンである v2.7.0 を使用します。
その後、Service タイプ `LoadBalancer` でダッシュボードをインターネットに公開することができ、これにより AWS アカウントに Network Load Balancer (NLB) が作成されます。

次のコマンドを実行して、Kubernetes ダッシュボードコンポーネントをインストールします。これにより、`kubernetes-dashboard` という新しい Namespace が作成され、すべてのリソースがそこにデプロイされます。

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
$ kubectl -n kubernetes-dashboard rollout status deployment/kubernetes-dashboard
$ kubectl -n kubernetes-dashboard get pods
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-64bcc67c9c-tt9vl   1/1     Running   0          66s
kubernetes-dashboard-5c8bd6b59-945zj         1/1     Running   0          66s
```

次に、新しく作成された `kubernetes-dashboard` Service をタイプ `LoadBalancer` にパッチを適用しましょう。

```bash
$ kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p='{"spec": {"type": "LoadBalancer"}}'
```

数分後、NLB が作成され、`kubernetes-dashboard` Service に公にアクセス可能なアドレスが表示されます。

```bash
$ kubectl -n kubernetes-dashboard get svc
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP      172.20.8.169     <none>                                                                    8000/TCP        3m
kubernetes-dashboard        LoadBalancer   172.20.218.132   ad0fbc5914a2c4d1baa8dcc32101196b-2094501166.us-west-2.elb.amazonaws.com   443:32762/TCP   3m1s
```

[GuardDuty Findings コンソール](https://console.aws.amazon.com/guardduty/home#/findings) に戻ると、`Policy:Kubernetes/ExposedDashboard` という検出結果が表示されます。ここでも検出結果の詳細、Action、および Detective Investigation の分析に時間をかけてください。

![Exposed dashboard finding](/docs/security/guardduty/log-monitoring/exposed-dashboard.webp)

次のコマンドを実行して、Kubernetes ダッシュボードコンポーネントをアンインストールします：

```bash
$ kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```
