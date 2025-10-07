---
title: "はじめに"
sidebar_position: 10
kiteTranslationSourceHash: d6b9b2ee6767fc60ab0e6e1591e31905
---

まずはhelmを使ってAWS Load Balancer controllerをインストールしましょう：

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

現在、クラスター内にIngressリソースはありません。以下のコマンドで確認できます：

```bash expectError=true
$ kubectl get ingress -n ui
No resources found in ui namespace.
```

また、タイプ`LoadBalancer`のServiceリソースも存在しません。以下のコマンドで確認できます：

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   10.100.221.103   <none>        80/TCP    29m
```

