---
title: "Worker Nodes"
sidebar_position: 50
description: "Bring worker nodes in an Amazon EKS Managed Nodegroup back to healthy state."
---

In the following scenarios for worker nodes we will learn how to troubleshoot various AWS EKS worker node issues. The different scenarios will walk through what is causing nodes fail to join the cluster or stay in 'Not Ready' status, then fixing with a solution. Before you begin, if you want to learn more about how worker nodes are deployed as part of managed node groups see [Fundamentals module](/docs/fundamentals/managed-node-groups).

<!-- :::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/workernodes/one
``` -->

<!-- The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:

- Pre-configure the base application from the introduction module
- Configure the AWS Load Balancer Controller in the Amazon EKS cluster
- Configure an ingress to get access to the UI via an AWS Load Balancer
- Introduce an issue to the configuration, so we can learn how to troubleshoot these types of issues

::: -->

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/workernodes/one/.workshop/terraform).

<!-- :::info Root Cause Analysis (RCA) Methodology

While we wait for the scenario to finalize its configuration, lets talk about the _RCA Methodology_ really quick.

The Root Cause Analysis (RCA) helps in identifying how and why an event or failure happened, allowing for corrective and preventive measures to be put in place and the RCA generally serves as input to a remediation process whereby corrective actions are taken to prevent the problem from reoccurring.

**_The method steps:_**

1. Identify and describe the problem clearly.
2. Collect data
3. Establish a timeline from the normal situation until the problem occurs.
4. Identify Root Cause
5. Distinguish between the root cause and other causal factors (e.g., using event correlation).
6. Establish a causal graph between the root cause and the problem.
7. Although the word "cause" is singular in RCA, experience shows that generally causes are plural. Therefore, look for multiple causes when carrying out RCA.

:::

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

If you get the same outputs, it means you are ready to start the troubleshooting. So please, continue with the next page. -->
