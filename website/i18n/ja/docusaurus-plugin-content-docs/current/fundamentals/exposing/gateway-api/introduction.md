---
title: "コントローラーのデプロイ"
sidebar_position: 5
tmdTranslationSourceHash: 'b2fbccdac6c96dae84b89bf2c3a59a3f'
---

以下の手順に従って、Gateway API サポートを有効にした AWS Load Balancer Controller をデプロイします。

`prepare-environment` ステップでは、すでに Gateway API の CRD がインストールされ、必要な IAM role が作成されています。ここでは、Helm を使用して AWS Load Balancer Controller をインストールします。

Gateway API サポートを有効にして AWS Load Balancer Controller をインストールします：

```bash wait=30
$ helm repo add eks-charts https://aws.github.io/eks-charts
$ helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --set "defaultTargetType=ip" \
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

コントローラーは Deployment として実行されます：

```bash
$ kubectl get deployment -n kube-system aws-load-balancer-controller
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           30s
```

クラスターで Gateway API の CRD が利用可能であることを確認します：

```bash
$ kubectl get crds | grep gateway
gatewayclasses.gateway.networking.k8s.io              [...]
gateways.gateway.networking.k8s.io                    [...]
httproutes.gateway.networking.k8s.io                  [...]
referencegrants.gateway.networking.k8s.io             [...]
```

現在、クラスターには Gateway リソースはありません：

```bash expectError=true
$ kubectl get gateway -A
No resources found
```

HTTPRoute リソースもありません：

```bash expectError=true
$ kubectl get httproute -A
No resources found
```

コントローラーがデプロイされたので、Gateway API リソースを作成して Application Load Balancer 経由でアプリケーションを公開する準備が整いました。

