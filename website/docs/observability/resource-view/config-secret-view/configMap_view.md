---
title: "ConfigMaps"
sidebar_position: 30
---

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) is a Kubernetes resource object to save configuration data in key-value format. The ConfigMaps are useful to store enviornmental variables, command-line arguments,application config that can be accessed by the applications deployed in the pods. ConfigMaps can also be stored as configuration files in a volume. These help the configuration data to be separated from the application code.

Click on the ConfigMap drill down and you can see all the configs for the cluster.

![Insights](/img/resource-view/config-configMap.jpg)

If you click on the ConfigMap <i>checkout</i> you can see the properties associated with it, in this case, the key REDIS_URL with the value of the redis endpoint. As you can see, the value is not encrypted and ConfigMaps should not be used to store any confidential key-value pairs.

![Insights](/img/resource-view/config-configmap-1.jpg)
