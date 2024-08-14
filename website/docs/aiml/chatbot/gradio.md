---
title: "Configuring the Gradio Web User Interface for Access"
sidebar_position: 40
---

After all the resources have been configured within the Ray Serve Cluster, it is now
important to directly access the Llama2 chatbot. The web interface is directly backed
through the Gradio UI.


:::tip
You can learn more about Load Balancers in the [Load Balancer module](../../fundamentals/exposing/loadbalancer/index.md) that's provided in this workshop.
:::

### Deploying Gradio Web User Interface

Once the AWS Load Balancer Controller has been installed, we can then deploy the Gradio UI components.

```file
manifests/modules/aiml/chatbot/gradio/gradio-ui.yaml
```

The components consist of a `Deployment`, `Service`, and `ConfigMap` to launch the application. In particular, the `Service` component is named gradio-service and is deployed as a `LoadBalancer`.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/gradio
namespace/gradio-llama2-inf2 created
configmap/gradio-app-script created
service/gradio-service created
deployment.apps/gradio-deployment created
```

To check the status of each component, run the following commands:

```bash
$ kubectl get deployments -n gradio-llama2-inf2
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
gradio-deployment   1/1     1            1           95s
```

```bash
$ kubectl get configmaps -n gradio-llama2-inf2
NAME                DATA   AGE
gradio-app-script   1      110s
kube-root-ca.crt    1      111s
```

### Accessing the Chatbot website

Once the load balancer has finished deploying, use the external ip-address to directly access
the website:

```bash
$ kubectl get services -n gradio-llama2-inf2
NAME             TYPE          ClUSTER-IP    EXTERNAL-IP                                                                      PORT(S)         AGE
gradio-service   LoadBalancer  172.20.84.26  k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com    80:30802/TCP    8m42s
```

To wait until the Network Load Balancer has finished provisioning, run the following command:

```bash
$ kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' service/gradio-service -n gradio-llama2-inf2 --timeout=5m
```

:::caution
In the case that the network load balancer fails to become available, make sure to delete the deployment pod.
Then run the wait command to access the website
:::

Now that our application is exposed to the outside world, lets try to access it by pasting that URL in your web browser. You will see the Llama2-chatbot and will be able to interact with it via asking questions.

<Browser url="http://k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/chatbot.webp').default}/>
</Browser>

This concludes the current lab on deploying the Meta Llama-2-13b Chatbot Model within EKS Cluster via Karpenter.
