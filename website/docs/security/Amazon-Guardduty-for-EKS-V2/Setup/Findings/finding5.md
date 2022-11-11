---
title: "Policy:Kubernetes/ExposedDashboard"
sidebar_position: 130
---

This finding informs you that Kubernetes dashboard for your cluster was exposed to the internet by a Load Balancer service. An exposed dashboard makes the management interface of your cluster accessible from the internet and allows adversaries to exploit any authentication and access control gaps that may be present.


To simulate this we will need to expose kubernetes dashboard to internet with service type LoadBalancer.

```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/Dashboard
```

With in few minutes we will see the finding `Policy:Kubernetes/ExposedDashboard` in guardduty portal. 

![](finding-4.png)


Cleanup
```bash
$ kubectl delete -k /workspace/modules/security/Guardduty/Dashboard
```
