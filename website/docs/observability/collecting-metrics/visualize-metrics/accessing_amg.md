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

After logging into the Grafana console, let's take a look at the datsources section. You should see the Amazon Managed Service for Prometheus workspace configured as a datasource already.

![Amazon Managed Service for Prometheus Datasource](/img/collecting-metrics/datasource.png)


Let's head over to the dashboard section and visualize the metrics collected by AWS Distro for Opentelemetry. We have already exported the dashboard "Kubernetes Cluster Monitoring" in Grafana.

![Grafana dashboard](/img/collecting-metrics/dashboard.png)


Click the dashboard "Kubernetes Cluster Monitoring" and let's review a panel within the dashboard.

The Total Usage panel shows the overall cluster utlization in terms of CPU, Memory and Filesystem usage

![Total Usage](/img/collecting-metrics/totalusage.png)

Similarly, you can import multiple dashboards within the Grafana console to analyze the application.

