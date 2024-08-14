---
title: "High Availability"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Prepare your EKS environment to handle high availability scenarios effectively."
---

TODO:

- have to delete deployment before? why? is that due to dev or what
- expected time for lab completion
- expected time for prepare-env (about 5 minutes without cleanup.sh and any previous applications)
- Lab overview
- Check info sections
- Are we able to chmod in backend?
- Check why the load balancer stopped working

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ chmod +x /manifests/modules/resiliency/.workshop/cleanup.sh
$ /manifests/modules/resiliency/.workshop/cleanup.sh
$ prepare-environment resiliency
```

This will make the following changes to your lab environment:

- Create the ingress load balancer
- Create RBAC and Rolebindings
- Install AWS Load Balancer controller
- Install ChaosMesh
- Create an IAM role for AWS Fault Injection Simulator (FIS)

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/resiliency/.workshop/terraform).
:::

In this lab, we'll look at...
information

:::info
For more information on these changes checkout:

- [Ingress Load Balancer](/docs/fundamentals/exposing/ingress/)
- [Integrating with Kubernetes RBAC](/docs/security/cluster-access-management/kubernetes-rbac)
- [Chaos Mesh](https://chaos-mesh.org/)
  :::
