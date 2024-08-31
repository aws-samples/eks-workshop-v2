---
title: "Deployments"
sidebar_position: 50
---

A [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) is a Kubernetes object that provides declarative updates to pods and replicaSets. It tells Kubernetes how to create or modify instances of pods. Deployments help to scale the number of replica pods and enable rollout or rollback a deployment version in a controlled manner. In this example (below), you can see 2 deployments for namespace <i>carts</i>.

![Insights](/img/resource-view/deploymentSet.jpg)

Click on the deployment <i>carts</i> and explore the configuration. You will see deployment strategy under Info, pod details under Pods, labels and deployment revision.

![Insights](/img/resource-view/deployment-detail.jpg)
