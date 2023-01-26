---
title: "Secrets"
sidebar_position: 35
---

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) is a Kubernetes resource object for storing sensitive peices of data such as username, passwords, tokens, and other credentials. Secrets are helpful to organize and distribute sensitive information across the pods in a cluster. Secrets can be used in a variety of ways, such as being mounted as data volumes or exposed as environment variables to be used by a container in a Pod.

Click on the Secrets drill down and you can see all the secrets for the cluster.

![Insights](/img/resource-view/config-secrets.jpg)

If you click on the Secrets <i>checkout-config</i> you can see the secrets associated with it. In this case, notice the encoded <i>token</i>. You should see the decoded value as well with the <i>decode</i> toggle button.

![Insights](/img/resource-view/config-secrets-1.jpg)
