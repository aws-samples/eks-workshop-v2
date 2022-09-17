---
title: "Multiple Ingress paths"
sidebar_position: 30
---

Lets create an additional `Ingress` resource with the following kustomization:

```file
exposing/ingress/ingress.yaml
```

This will cause the AWS Load Balancer Controller to provision an Application Load Balancer and configure it to route traffic to the Pods for the `ui` application.

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k /workspace/modules/exposing/ingress
```

Let's inspect the `Ingress` object created:

```bash
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                            PORTS   AGE
ui     alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      15s
```