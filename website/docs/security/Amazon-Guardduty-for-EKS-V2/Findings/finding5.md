---
title: "ExposedKubernetesDashboard"
sidebar_position: 130
---

This finding informs you that Kubernetes dashboard for your cluster was exposed to the internet by a Load Balancer service. An exposed dashboard makes the management interface of your cluster accessible from the internet and allows adversaries to exploit any authentication and access control gaps that may be present.

To simulate this we will need to expose the Kubernetes dashboard to the Internet with service type LoadBalancer.

Firstly we will install the Kubernetes dashboard component. Based on [release notes](https://github.com/kubernetes/dashboard/releases/tag/v2.5.1) v2.5.1 is compatable with k8's cluster version 1.23 hence we are picking v2.5.1 for our simulation.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
```

Let us patch the `kubernetes-dashboard` service to be type LoadBalancer.

```bash
$ kubectl patch patch svc kubernetes-dashboard -n kubernetes-dashboard -p='{"spec": {"type": "LoadBalancer"}}'
```

Within a few minutes we will see the finding `Policy:Kubernetes/ExposedDashboard` in the GuardDuty portal.

![](ExposedDashboard.png)

Cleanup:

```bash
$ kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
```