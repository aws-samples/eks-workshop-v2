---
title: "Namespaces"
sidebar_position: 40
---

[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces) are a mechanism to organize clusters which can be very helpful when different teams or projects share a Kubernetes cluster. In our sample application we have microservices - carts, checkout, catalog, assets which all share the same cluster using the namespace construct.

![Insights](/img/resource-view/cluster-ns.jpg)
