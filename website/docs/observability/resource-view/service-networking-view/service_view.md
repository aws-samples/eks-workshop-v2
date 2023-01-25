---
title: "Services and Endpoints"
sidebar_position: 30
---

[Service](https://kubernetes.io/docs/concepts/services-networking/service/) resource view displays all the services that expose applications running on set of pods in a cluster.

![Insights](/img/resource-view/service-view.jpg)

If you select the service <i>cart</i> the view displayed will have details about the service in Info section including selector(The set of pods targeted by a service is usually determined by a selector), the protocol and port it is running on and any labels and annotations. 

![Insights](/img/resource-view/service-detail.jpg)

Pods expose themselves through endpoints to a service. An endpoint is an resource that gets an IP address and port of pods assigned dynamically to it. An endpoint is reference by a Kubernetes service.

![Insights](/img/resource-view/service-endpoint.png)

For this sample application, click on <i> Endpoints</i> and it will list all the endpoints for your cluster. 

![Insights](/img/resource-view/service-endpoint.jpg)

Click on the <i>catalog</i> endpoint and when you explore the details you can see the IP address and port associated with the endpoint along with Info, Labels and Annotations sections.

![Insights](/img/resource-view/service-endpoint-detail.jpg)
