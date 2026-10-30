---
title: "Lab setup"
sidebar_position: 60
---

In this lab, we are going to implement network policies for the sample application deployed in the lab cluster. The sample application component architecture is shown below.

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

Each component in the sample application is implemented in its own namespace. For example, the **'ui'** component is deployed in the **'ui'** namespace, whereas the **'catalog'** web service and **'catalog'** MySQL database are deployed in the **'catalog'** namespace.

Currently, there are no network policies that are defined, and any component in the sample application can communicate with any other component or any external service. For example, the 'catalog' component can directly communicate with the 'checkout' component. We can validate this using the below commands:

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health | jq
{
  "status": "ok",
  "info": {
    "chaos": {
      "status": "up"
    }
  },
  "error": {},
  "details": {
    "chaos": {
      "status": "up"
    }
  }
}
```

Let us make required configuration changes in our EKS Auto Mode cluster to enable network policies. For that, create a ConfigMap for VPC container network interface (CNI) that provides networking for the cluster.

::yaml{file="manifests/modules/fastpaths/operators/network-policies/vpc-cni-policies.yaml" paths="data.enable-network-policy-controller"}

1. This will enable the network policy controller in the vpc-cni plugin

Apply this configuration:

```bash timeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpaths/operators/network-policies/vpc-cni-policies.yaml
```

Let's now implement some network rules so we can better control the network traffic flow for the sample application.
