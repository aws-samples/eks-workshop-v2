---
title: "Services and Endpoints"
sidebar_position: 20
---

To view the Kubernetes service and networking resources, click on the <i>Resources</i> tab. Drill down to the <i>Service and Networking</i> section and you can view several the Kubernetes API resource types that are part of service and networking. This lab exercise details ways to expose an application running on a set of Pods as Service, Endpoints and Ingresses.

[Service](https://kubernetes.io/docs/concepts/services-networking/service/) resource view displays all the services that expose applications running on set of pods in a cluster.

![Insights](/img/resource-view/service-view.jpg)

If you select the service <i>cart</i> the view displayed will have details about the service in Info section including selector(The set of pods targeted by a service is usually determined by a selector), the protocol and port it is running on and any labels and annotations.
Pods expose themselves through endpoints to a service. An endpoint is an resource that gets an IP address and port of pods assigned dynamically to it. An endpoint is reference by a Kubernetes service.

![Insights](/img/resource-view/service-endpoint.png)

For this sample application, click on <i> Endpoints</i> and explore the details of the IP address and port associated with the endpoint along with Info, Labels and Annotations sections.
