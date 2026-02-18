---
title: "サービスがエンドポイントを登録していない問題"
sidebar_position: 32
tmdTranslationSourceHash: fc331a5ef68d4afb716ae012b9f5dd05
---

このセクションでは、Application Load Balancer (ALB) が Kubernetes サービスのエンドポイントを正しく登録しない理由についてトラブルシューティングを行います。ALB が正常に作成されたにもかかわらず、バックエンドサービスの設定に問題があるためアプリケーションにアクセスできません。

### ステップ 1: エラーの確認

ALB を通じてアプリケーションにアクセスすると、「Backend service does not exist（バックエンドサービスが存在しません）」というエラーが表示されます：

![ALb-Backend-DoesNotExist](/docs/troubleshooting/alb/alb-does-not-exist.webp)

イングレスは正常に作成されたため、これは Kubernetes イングレスとサービス間の通信に問題があることを示唆しています。

### ステップ 2: サービス設定の確認

サービス設定を調べてみましょう：

```bash
$ kubectl -n ui get service/ui -o yaml
```

```yaml {12}
apiVersion: v1
kind: Service
metadata:
  annotations: ...
  labels:
    app.kubernetes.io/component: service
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/instance: ui
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ui
    helm.sh/chart: ui-0.0.1
  name: ui
  namespace: ui
spec:
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
  selector:
    app.kubernetes.io/component: service
    app.kubernetes.io/instance: ui
    app.kubernetes.io/name: ui-app
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

### ステップ 3: イングレス設定の確認

次にイングレス設定を確認します：

```bash
$ kubectl get ingress/ui -n ui -o yaml
```

```yaml {23}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    ...
  finalizers:
  - ingress.k8s.aws/resources
  generation: 1
  name: ui
  namespace: ui
  resourceVersion: "4950883"
  uid: 327b899c-405e-431b-8d67-32578435f0b9
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: service-ui
            port:
              number: 80
        path: /
        pathType: Prefix
...
```

イングレスが `service-ui` という名前のサービスを使用するように設定されていますが、実際のサービス名は `ui` であることに注目してください。

### ステップ 4: イングレス設定の修正

イングレスを正しいサービス名を指すように更新しましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/alb/creating-alb/fix_ingress
```

修正後の設定は次のようになります：

```yaml {10}
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port:
                  number: 80
```

### ステップ 5: サービスエンドポイントの確認

サービス名を修正した後も、まだ 503 エラーが表示されます：

![ALb-503-ERROR](/docs/troubleshooting/alb/alb-503.webp)

これは、サービスのバックエンドエンドポイントに問題があることを示唆しています。エンドポイントを確認してみましょう：

```bash
$ kubectl -n ui get endpoints ui
NAME   ENDPOINTS   AGE
ui     <none>     13d
```

エンドポイントが空であることは、サービスが Pod バックエンドを適切に選択していないことを示しています。

### ステップ 6: サービスと Pod のラベルの比較

デプロイメントの Pod ラベルを調べてみましょう：

```bash
$ kubectl -n ui get deploy/ui -o yaml
```

```yaml {34}
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    ...
  name: ui
  namespace: ui
  ..
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/component: service
      app.kubernetes.io/instance: ui
      app.kubernetes.io/name: ui
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations:
        prometheus.io/path: /actuator/prometheus
        prometheus.io/port: "8080"
        prometheus.io/scrape: "true"
      creationTimestamp: null
      labels:
        app.kubernetes.io/component: service
        app.kubernetes.io/created-by: eks-workshop
        app.kubernetes.io/instance: ui
        app.kubernetes.io/name: ui
    spec:
      containers:
...

```

これをサービスセレクタと比較してみましょう：

```bash
$ kubectl -n ui get svc ui -o yaml
```

```yaml {22}
apiVersion: v1
kind: Service
metadata:
  annotations:
    ...
  labels:
    app.kubernetes.io/component: service
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/instance: ui
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ui
    helm.sh/chart: ui-0.0.1
  name: ui
  namespace: ui
  resourceVersion: "5000404"
  uid: dc832144-b2a1-41cd-b7a1-8979111da677
spec:
  ...
  selector:
    app.kubernetes.io/component: service
    app.kubernetes.io/instance: ui
    app.kubernetes.io/name: ui-app
  sessionAffinity: None
  type: ClusterIP
...
```

サービスセレクタの `app.kubernetes.io/name: ui-app` が Pod ラベルの `app.kubernetes.io/name: ui` と一致していません。

:::tip
サービスセレクタを以下のように更新することができます：

```text
kubectl edit service <service-name> -n <namespace>
```

または

```text
kubectl patch service <service-name> -n <namespace> --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value": {"key1": "value1", "key2": "value2"}}]'
```

:::

### ステップ 7: サービスセレクタの修正

サービスセレクタを Pod ラベルと一致するように更新しましょう：

```bash timeout=960 hook=fix-7 hookTimeout=960
$ kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/alb/creating-alb/fix_ui
```

修正を適用した後、ブラウザを更新してください。これでUI アプリケーションが表示されるはずです：

![ALB-UI-APP](/docs/troubleshooting/alb/alb-working.webp)

:::tip
サービスと Pod の接続をトラブルシューティングする際は：

1. サービスセレクタが Pod ラベルと完全に一致することを常に確認する
2. `kubectl get endpoints` を使用して Pod の選択を確認する
3. ラベル名と値のタイプミスがないか確認する

:::

サービス設定の問題を修正し、ALB のトラブルシューティング演習を完了しました！お疲れ様でした。
