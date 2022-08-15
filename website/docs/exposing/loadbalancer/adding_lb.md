---
title: "Creating the load balancer"
sidebar_position: 20
---

Lets create an additional `Service` that provisions a load balancer with the following kustomization:

```file
exposing/load-balancer/nlb/nlb.yaml
```

This `Service` will create a Network Load Balancer that listens on port 80 and forwards connections to the `ui` Pods on port 8080. An NLB is a layer 4 load balancer that on our case operates at the TCP layer.

```bash timeout=180 hook=add-lb hookTimeout=430
kubectl apply -k ~/modules/exposing/load-balancer/nlb
```

Lets inspect the `Service` resources for the `ui ` application again:

```bash
kubectl get svc -n ui
NAME     TYPE           CLUSTER-IP       EXTERNAL-IP                                           PORT(S)        AGE
ui       ClusterIP      172.20.62.119    none                                                  80/TCP         4m30s
ui-nlb   LoadBalancer   172.20.109.218   k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com   80:30396/TCP   14s
```

Now we see two separate resources, with the new `ui-nlb` entry being of type `LoadBalancer`. Most importantly note it has an "external IP" value, this the DNS entry that can be used to access our application from outside the Kubernetes cluster.