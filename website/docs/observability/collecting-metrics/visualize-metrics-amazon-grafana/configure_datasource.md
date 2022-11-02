---
title: "Configuring datasource for Amazon Grafana"
sidebar_position: 35
---
#### Login to AMG workspace

Click on the Grafana workspace URL in the Summary section

![Login to AMG workspace](/img/collecting-metrics/amg6.png)

This will take you to the SAML login screen, where you can provide the UserId and Password that you created as part of prerequisites.


![SAML Login](/img/collecting-metrics/amg7.png)

#### Configure AMP data source

Select `AWS services` from the AWS logo on the left navigation bar, which will take you to the screen as shown below showing all the AWS data sources available for you to choose from.

![AWS Datasources](/img/collecting-metrics/amg8.png)

Select Prometheus from the list, select the AWS Region where you created the AMP workspace. This will automatically populate the AMP workspaces available in that Region as shown below.


![AMP data source config](/img/collecting-metrics/amg9.png)

Simply select the `eks-observability-workspace` workspace from the list and click `Add data sources`. Once added you will able to see that the AMP data source is authenticated through SigV4 protocol. Grafana (7.3.5 and above) has the AWS SigV4 proxy built-in as a plugin which makes this possible.

![AMP configuration](/img/collecting-metrics/amg10.png)

#### Query Metrics

In this section we will be importing a public Grafana dashboard that allows us to visualize metrics from a Kubernetes environment.

Go to the `plus` sign on the left navigation bar and select `Import`.
![Import link](/img/collecting-metrics/amg11.png)

In the Import screen, type `3119` in `Import via grafana.com` textbox and click `Load`

Select the AMP data source in the drop down at the bottom and click on `Import`


Once complete, you will be able to see the Grafana dashboard showing metrics from the EKS cluster through AMP data source as shown below.

![3119 Dashboard](/img/collecting-metrics/amg12.png)

You can also create your own custom dashboard using PromQL by creating a custom dashboard and adding a panel connecting AMP as the data source.
