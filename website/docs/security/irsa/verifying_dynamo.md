---
title: "Verifying DynamoDB Access"
sidebar_position: 50
---

Now, with the `carts` Pod picking the `carts` ServiceAccount which is confiured to access DynamoDB, access the web store again and navigate to the shopping cart. 


```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

The `carts` Pod is able to reach the DynamodDB service and the shopping cart is now accessible!

![Application Success](./assets/success.png)

