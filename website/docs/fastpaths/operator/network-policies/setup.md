---
title: "Lab setup"
sidebar_position: 60
---

In this lab, we are going to implement network policies for the sample application deployed in the lab cluster. The sample application component architecture is shown below.

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

Each component in the sample application is implemented in its own namespace. For example, the **'ui'** component is deployed in the **'ui'** namespace, whereas the **'catalog'** web service and **'catalog'** MySQL database are deployed in the **'catalog'** namespace.

Currently, there are no network policies that are defined, and any component in the sample application can communicate with any other component or any external service. For example, the 'catalog' component can directly communicate with the 'checkout' component. We can validate this using the below commands:

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health
{"status":"ok","info":{},"error":{},"details":{}}
```

Let us start by implementing some network rules so we can better control the follow of traffic for the sample application.
