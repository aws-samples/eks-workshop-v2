---
title: "はじめに"
sidebar_position: 10
tmdTranslationSourceHash: 89f042d87495980d35d5b04b0326cfea
---

まず、helmを使用してAWS Load Balancerコントローラをインストールしましょう：

```bash wait=10
$ helm repo add eks-charts https://aws.github.io/eks-charts
$ helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --wait
Release "aws-load-balancer-controller" does not exist. Installing it now.
NAME: aws-load-balancer-controller
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

クラスター内の現在の`Service`リソースを見て、マイクロサービスが内部でのみアクセス可能であることを確認できます：

```bash
$ kubectl get svc -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
carts       carts              ClusterIP   172.20.180.149   <none>        80/TCP                                  1h
carts       carts-dynamodb     ClusterIP   172.20.92.137    <none>        8000/TCP                                1h
catalog     catalog            ClusterIP   172.20.83.84     <none>        80/TCP                                  1h
catalog     catalog-mysql      ClusterIP   172.20.181.252   <none>        3306/TCP                                1h
checkout    checkout           ClusterIP   172.20.77.176    <none>        80/TCP                                  1h
checkout    checkout-redis     ClusterIP   172.20.32.208    <none>        6379/TCP                                1h
orders      orders             ClusterIP   172.20.146.72    <none>        80/TCP                                  1h
orders      orders-postgresql  ClusterIP   172.20.54.235    <none>        3306/TCP                                1h
ui          ui                 ClusterIP   172.20.62.119    <none>        80/TCP                                  1h
```

現在、すべてのアプリケーションコンポーネントは`ClusterIP`サービスを使用しており、同じKubernetesクラスター内の他のワークロードのみがアクセスできます。ユーザーがアプリケーションにアクセスできるようにするには、`ui`アプリケーションを公開する必要があります。この例では、タイプ`LoadBalancer`のKubernetesサービスを使用して行います。

`ui`コンポーネントの現在のサービス仕様を詳しく見てみましょう：

```bash
$ kubectl -n ui describe service ui
Name:              ui
Namespace:         ui
Labels:            app.kubernetes.io/component=service
                   app.kubernetes.io/created-by: eks-workshop
                   app.kubernetes.io/instance=ui
                   app.kubernetes.io/managed-by=Helm
                   app.kubernetes.io/name=ui
                   helm.sh/chart=ui-0.0.1
Annotations:       <none>
Selector:          app.kubernetes.io/component=service,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                172.20.62.119
IPs:               172.20.62.119
Port:              http  80/TCP
TargetPort:        http/TCP
Endpoints:         10.42.105.38:8080
Session Affinity:  None
Events:            <none>
```

先ほど確認したように、現在はタイプ`ClusterIP`を使用しており、このモジュールでの私たちの課題は、リテールストアのユーザーインターフェイスがパブリックインターネット経由でアクセスできるようにこれを変更することです。
