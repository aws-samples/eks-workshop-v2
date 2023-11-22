---
title: "Lab setup"
sidebar_position: 60
---

In this lab, we are going to implement network policies for the sample application deployed in the lab cluster. The sample application component architecture is shown below.

<img src={require('@site/static/img/sample-app-screens/architecture.png').default}/>

We can access the sample application using the url from below command

```bash
$ wait-for-lb $(kubectl get ingress -n ui alb-ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
Waiting for k8s-ui-albui-634ca3fbcb-952136118.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-albui-634ca3fbcb-952136118.us-west-2.elb.amazonaws.com
```

<browser url='http://k8s-ui-albui-634ca3fbcb-952136118.us-west-2.elb.amazonaws.com/home'>
<img src={require('@site/static/img/sample-app-screens/home.png').default}/>
</browser>

As you can see from the architecture diagram of the sample application, each component is implemented in its own namespace. For example, the **'ui'** component is deployed in the **'ui'** namespace, whereas the **'catalog'** web service and **'catalog'** MySQL database are deployed in the **'catalog'** namespace.

For network policies to work, the EKS cluster must have Amazon VPC CNI plugin version v1.14.0-eksbuild.3 or later, as is the case with the current EKS cluster you will be working on. For more information on how to configure network policies for the EKS cluster, refer to this [user guide](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html)

Currently, there are no network policies that are defined, and any component in the sample application can communicate with any other component or any external service. For example, the 'catalog' component can directly communicate with the 'checkout' component. We can validate this using the below command:

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health
{"status":"ok","info":{},"error":{},"details":{}}
```

Let us start by implementing some network rules so we can better control the follow of traffic for the sample application.