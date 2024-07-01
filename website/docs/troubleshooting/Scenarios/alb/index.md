---
title: "Load balancer scenario"
sidebar_position: 20
chapter: true
sidebar_custom_props: { "module": true }
description: "Expose HTTP and HTTPS routes to the outside world using Ingress API on Amazon Elastic Kubernetes Service And introduces an issue to the configuration"
---

{{% required-time %}}

On this scenario we will learn how to troubleshoot various AWS Load Balancer Controller deployment issues, as well as ingress objects created. If you want to learn more about how a Load balancer controller works please check out the [Fundamentals module] (./fundamentals/)

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/alb
```

This will make the following changes to your lab environment:

- Pre-configure the base application from the introduction module
- Configure the AWS Load Balancer Controller in the Amazon EKS cluster
- Configure an ingress to get access to the UI via an AWS Load Balancer
- Introduce an issue to the configuration, so we can learn how to troubleshoot these types of issues
  :::

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/alb/.workshop/terraform).

Now let's verify if the service and ingress is up and running, so we can start troubleshooting the scenario.

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.224.112   <none>        80/TCP    12d
```

and

```bash
$ kubectl get ingress -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      11m

```

Now, do not panic!! the output is expected since it is supposed the ingress/alb shouldn't be created. Let's verify the load balancer was indeed not created:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[]
```

If you get the same outputs, it means you are ready to start the troubleshooting. So please, continue with the next page.
