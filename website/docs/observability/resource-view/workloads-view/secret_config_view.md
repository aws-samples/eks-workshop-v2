---
title: "ConfigMaps and Secrets"
sidebar_position: 30
---

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) is a Kubernetes resource object to save configuration data in key-value format. The ConfigMaps are useful to store environment variables, command-line arguments, application config that can be accessed by the applications deployed in the pods. ConfigMaps can also be stored as configuration files in a volume. These help the configuration data to be separated from the application code.

Click on the ConfigMap drill down and you can see all the configs for the cluster.

![Insights](/img/resource-view/config-configMap.jpg)

If you click on the ConfigMap <i>checkout</i> you can see the properties associated with it, in this case, the key REDIS_URL with the value of the redis endpoint. As you can see, the value is not encrypted and ConfigMaps should not be used to store any confidential key-value pairs.

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) is a Kubernetes resource object for storing sensitive pieces of data such as username, passwords, tokens, and other credentials. Secrets are helpful to organize and distribute sensitive information across the pods in a cluster. Secrets can be used in a variety of ways, such as being mounted as data volumes or exposed as environment variables to be used by a container in a Pod.

Click on the Secrets drill down and you can see all the secrets for the cluster.

![Insights](/img/resource-view/config-secrets.jpg)

If you click on the Secrets <i>checkout-config</i> you can see the secrets associated with it. In this case, notice the encoded <i>token</i>. You should see the decoded value as well with the <i>decode</i> toggle button.
