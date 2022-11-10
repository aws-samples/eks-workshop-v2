---
title: "Accessing Grafana"
sidebar_position: 30
---

In instance of Grafana has been pre-installed in your cluster. To access it you first need to retrieve the URL:

```bash hook=check-grafana
$ kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}'
k8s-grafana-grafana-123497e39be-2107151316.us-west-2.elb.amazonaws.com
```

Opening this URL in a browser will bring up a login screen. To retrieve the credentials for the user query the secret created by the Grafana helm chart:

```bash
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d
```
