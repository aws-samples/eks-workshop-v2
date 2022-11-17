---
title: "Introduction"
sidebar_position: 10
---

We can confirm our service is only accessible internally by taking a look at the current `Service` resources in the cluster:

```bash
$ kubectl get svc -A
```

All of our application components are currently using `ClusterIP` services, which only allows access to other workloads in the same Kubernetes cluster. In order for users to access our application we need to expose the `ui` application, and in this example we'll do so using a Kubernetes `Service` of type `LoadBalancer`.

First, lets take a closer look at the current specification of the `Service` for the `ui` component:

```bash
$ kubectl -n ui describe service ui
Name:              ui
Namespace:         ui
Labels:            app.kubernetes.io/component=service
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

As we saw earlier, this is currently using a type `ClusterIP` and our task in this module to is fix this.