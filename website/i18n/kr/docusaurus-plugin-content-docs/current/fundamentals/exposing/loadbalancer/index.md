---
title: "Load Balancers"
chapter: true
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Manage AWS load balancers to route traffic to workloads on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip 시작하기 전에

이 섹션을 위한 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment exposing/load-balancer
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Creates an IAM role required by the AWS Load Balancer Controller

[**여기**](https://github.com/aws-samples/eks-workshop-v2/tree/stable/manifests/modules/exposing/load-balancer/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.

You can view the Terraform that applies these changes \[here\].

:::

Kubernetes uses services to expose pods outside of a cluster. One of the most popular ways to use services in AWS is with the `LoadBalancer` type. With a simple YAML file declaring your service name, port, and label selector, the cloud controller will provision a load balancer for you automatically.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: search-svc # the name of our service
spec:
  type: loadBalancer
  selector:
    app: SearchApp # pods are deployed with the label app=SearchApp
  ports:
    - port: 80
```

This is great because of how simple it is to put a load balancer in front of your application. The service spec has been extended over the years with annotations and additional configuration. A second option is to use an ingress rule and an ingress controller to route external traffic into Kubernetes pods.

![IP mode](./assets/ui-nlb-instance.webp)

In this chapter we'll demonstrate how to expose an application running in the EKS cluster to the Internet using a layer 4 Network Load Balancer.