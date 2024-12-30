---
title: "Validating the Ingress"
sidebar_position: 15
---

As part of the lab pre-requisites, an Ingress resource was created and the AWS Load Balancer Controller created a corresponding ALB based on the Ingress configuration. It will take several minutes for the ALB to provision and register its targets. Let's validate the Ingress resource and the ALB before continuing.

Let's inspect the Ingress object created:

```bash hook=validate-ingress hookTimeout=430
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                                      PORTS   AGE
ui     alb     *       k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com   80      3m51s
```

To wait until the load balancer has finished provisioning you can run this command:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
Waiting for k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-107943159.us-west-2.elb.amazonaws.com
```

Once provisioned, you can access it in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
