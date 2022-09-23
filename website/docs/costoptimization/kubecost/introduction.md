---
title: "Introduction"
sidebar_position: 10
---

Kubecost has already been deployed into your cluster. To access the Kubecost dashboard we will expose it through a `kubectl port-forward` command. Expose the Kubecost dashboard by running the following command:

```bash
kubectl port-forward --namespace kubecost deployment/cost-analyzer 9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```

Open a browser and access `http://localhost:9090` to reach the Kubecost dashboard.

<browser url='http://localhost:9090/overview'>
<img src="https://blog.kubecost.com/assets/images/grafana-cloud-with-kubecost/image_1.png"/>
</browser>
