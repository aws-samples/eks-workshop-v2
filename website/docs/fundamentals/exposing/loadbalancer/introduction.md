---
title: "Introduction"
sidebar_position: 10
---

We can confirm our microservices are only accessible internally by taking a look at the current Service resources in the cluster:

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

All of our application components are currently using `ClusterIP` services, which only allows access to other workloads in the same Kubernetes cluster. In order for users to access our application we need to expose the `ui` application, and in this example we'll do so using a Kubernetes Service of type `LoadBalancer`.

First, lets take a closer look at the current specification of the Service for the `ui` component:

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
Endpoints:         10.42.11.143:8080
Session Affinity:  None
Events:            <none>
```

As we saw earlier this is currently using a type `ClusterIP` and our task in this module to is change this so that the retail store user interface is accessible over the public Internet.
