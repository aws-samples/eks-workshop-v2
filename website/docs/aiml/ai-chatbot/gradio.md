---
title: "Configuring the Gradio Web User Interface for Access"
sidebar_position: 40
---

After all the resources have been configured within the Ray Serve Cluster, it is now
important to directly access the Llama2 chatbot. The web interface is directly backed
through the Gradio UI.

### Creating the load balancer

For Gradio UI to properly grant access for using the chatbot interface, a load balancer must
be created to establish secure entry to the website.

:::tip
You can learn more about Load Balancers in the [Load Balancer module](../../fundamentals/exposing/loadbalancer/index.md) that's provided in this workshop.
:::

First let's install the AWS Load Balancer controller using helm:

```bash wait=10
$ helm repo add eks-charts https://aws.github.io/eks-charts
$ helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --wait
Release "aws-load-balancer-controller" does not exist. Installing it now.
NAME: aws-load-balancer-controller
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

### Deploying Gradio Web User Interface

Once the AWS Load Balancer Controller has been installed, we can then deploy the Gradio UI components.

```file
manifests/modules/aiml/chatbot/gradio/gradio-ui.yaml
```

The components consist of a `Deployment`, `Service`, and `ConfigMap` to launch the application. In particular, the `Service` component is named gradio-service and is deployed as a `LoadBalancer`.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/gradio
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

Now that our application is exposed to the outside world, lets try to access it by pasting that URL in your web browser. You will see the Llama2-chatbot and will be able to interact with it via asking questions.

<Browser url="http://k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/chatbot.webp').default}/>
</Browser>

This concludes the current lab on deploying the Meta Llama-2-13b Chatbot Model within EKS Cluster via Karpenter.
