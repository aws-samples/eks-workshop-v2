---
title: "시작하기"
sidebar_position: 10
---

먼저 helm을 사용하여 AWS Load Balancer 컨트롤러를 설치해보겠습니다:

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

클러스터의 현재 Service 리소스를 살펴봄으로써 우리의 마이크로서비스가 내부에서만 접근 가능한지 확인할 수 있습니다:

```bash
$ kubectl get svc -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
assets      assets           ClusterIP   172.20.119.246   <none>        80/TCP                                  1h
carts       carts            ClusterIP   172.20.180.149   <none>        80/TCP                                  1h
carts       carts-dynamodb   ClusterIP   172.20.92.137    <none>        8000/TCP                                1h
catalog     catalog          ClusterIP   172.20.83.84     <none>        80/TCP                                  1h
catalog     catalog-mysql    ClusterIP   172.20.181.252   <none>        3306/TCP                                1h
checkout    checkout         ClusterIP   172.20.77.176    <none>        80/TCP                                  1h
checkout    checkout-redis   ClusterIP   172.20.32.208    <none>        6379/TCP                                1h
orders      orders           ClusterIP   172.20.146.72    <none>        80/TCP                                  1h
orders      orders-mysql     ClusterIP   172.20.54.235    <none>        3306/TCP                                1h
rabbitmq    rabbitmq         ClusterIP   172.20.107.54    <none>        5672/TCP,4369/TCP,25672/TCP,15672/TCP   1h
ui          ui               ClusterIP   172.20.62.119    <none>        80/TCP                                  1h
```

현재 우리의 모든 애플리케이션 컴포넌트는 `ClusterIP` 서비스를 사용하고 있으며, 이는 같은 쿠버네티스 클러스터 내의 다른 워크로드에서만 접근할 수 있게 합니다. 사용자가 우리 애플리케이션에 접근할 수 있도록 하기 위해서는 `ui` 애플리케이션을 노출해야 하며, 이 예제에서는 `LoadBalancer` 타입의 쿠버네티스 서비스를 사용하여 이를 수행할 것입니다.

`ui `컴포넌트의 현재 서비스 명세를 자세히 살펴보겠습니다:

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

앞서 보았듯이 현재는 `ClusterIP` 타입을 사용하고 있으며, 이 모듈에서 우리의 작업은 리테일 스토어 사용자 인터페이스가 공용 인터넷을 통해 접근 가능하도록 이를 변경하는 것입니다.