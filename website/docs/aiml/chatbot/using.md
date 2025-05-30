---
title: "Using a chat bot"
sidebar_position: 60
---

After all the resources have been configured within the Ray Serve cluster, it's now time to directly perform inference through the Mistral-7B-Instruct-v0.3 model with a chat bot. The web interface is powered by the [Gradio](https://github.com/gradio-app/gradio) package.

We'll deploy the application with the following Kubernetes resources:

```file
manifests/modules/aiml/chatbot/gradio-mistral/gradio-ui.yaml
```

The components consist of a `Deployment`, `Service`, and `ConfigMap` to launch the application. In particular, the `Service` component is named `gradio-service` and is deployed as a `LoadBalancer`.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/gradio-mistral
namespace/gradio-mistral-trn1 created
configmap/gradio-app-script created
service/gradio-service created
deployment.apps/gradio-deployment created
```

To check the status of each component, run the following commands:

```bash
$ kubectl get deployments -n gradio-mistral-trn1
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
gradio-deployment   1/1     1            1           95s
```

```bash
$ kubectl get configmaps -n gradio-mistral-trn1
NAME                DATA   AGE
gradio-app-script   1      110s
kube-root-ca.crt    1      111s
```

Once the load balancer has finished deploying, use the external IP address to directly access the website:

```bash wait=10
$ kubectl get services -n gradio-mistral-trn1
NAME             TYPE          ClUSTER-IP    EXTERNAL-IP                                                                      PORT(S)         AGE
gradio-service   LoadBalancer  172.20.84.26  k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com    80:30802/TCP    8m42s
```

To wait until the Network Load Balancer has finished provisioning, run the following command:

```bash wait=300 timeout=900
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get service -n gradio-mistral-trn1 gradio-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Now that our application is exposed to the outside world, let's access it by pasting the URL in your web browser. You will see the chat bot powered by the Mistral-7B-Instruct-v0.3 model and will be able to interact with it by asking questions.

<Browser url="http://k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/gardio_mistral_SS.png').default}/>
</Browser>

This concludes the current lab on deploying the Mistral-7B-Instruct-v0.3 model on an EKS cluster and interacting with it through a simple chat bot interface.
