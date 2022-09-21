---
title: "Collecting & analyzing metrics using ADOT, Amazon Managed Prometheus & Amazon Managed Grafana"
sidebar_position: 70
---

Let's first `save & test` the datasource in the Amazon Managed Grafana console. Login to the Grafana URL using SAML / SSO credentials and perform the below steps:

Open your Grafana workspace and under Configuration -> Data sources, you should see aws-observability-accelerator. Open and click `Save & test`. You should see a notification confirming that the Amazon Managed Service for Prometheus workspace is ready to be used on Grafana.

Let's next verify the dashboards created:
Go to the Dashboards panel of your Grafana workspace. You should see a list of dashboards under the `Observability Accelerator Dashboards`

![Grafana Dashboards](https://github.com/saaish/eks-workshopv2/blob/main/images/190000716-29e16698-7c90-49d6-8c37-79ca1790e2cc.png)

Open a specific dashboard and you should be able to view its visualization

![Cluster Utiliation](https://github.com/saaish/eks-workshopv2/blob/main/images/187515925-67864dd1-2b35-4be0-a15e-1e36805e8b29.png)

This concludes the end of the module