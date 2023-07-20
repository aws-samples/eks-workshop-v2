---
title: "Introduction"
sidebar_position: 10
---

Kubecost has already been deployed into your cluster. We can check to see if it's up and running. Run:

```bash hook=kubecost-deployment
$ kubectl get deployment -n kubecost
kubecost-cost-analyzer        1/1     1            1           16m
kubecost-kube-state-metrics   1/1     1            1           16m
kubecost-prometheus-server    1/1     1            1           16m
```

Kubecost has been exposed using a `LoadBalancer` service, and we can find the URL to access it like so:

```bash
$ kubectl get service -n kubecost kubecost-cost-analyzer \
    -o jsonpath="{.status.loadBalancer.ingress[*].hostname}:9090{'\n'}"
a9e6e1f6b373f44bf8e1c1cb70f6a95b-1567842963.us-west-2.elb.amazonaws.com:9090
```

Open this link in your browser to access Kubecost:

<browser url='http://a9e6e1f6b373f44bf8e1c1cb70f6a95b-1567842963.us-west-2.elb.amazonaws.com:9090'>
<img src={require('./assets/overview.png').default}/>
</browser>