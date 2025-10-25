---
title: "Testing the application"
sidebar_position: 40
---

Now that we've provisioned our DynamoDB table using Crossplane Compositions, let's test the application to ensure it's working correctly with the new table.

First, we need to restart the pods to ensure they're using the updated configuration:

```bash
$ kubectl rollout restart -n carts deployment/carts
$ kubectl rollout status -n carts deployment/carts --timeout=2m
deployment "carts" successfully rolled out
```

To access the application, we'll use the same load balancer as in the previous section. Let's retrieve its hostname:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

You can now access the application by copying this URL into your web browser. You'll see the web store's user interface, allowing you to navigate the site as a user would.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

To verify that the **Carts** module is indeed using the newly provisioned DynamoDB table, follow these steps:

1. Add a few items to your cart in the web interface.
2. Observe that the items appear in your cart, as shown in the screenshot below:

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

To confirm that these items are being stored in the DynamoDB table, run the following command:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

This command will display the contents of the DynamoDB table, which should include the items you've added to your cart.

Congratulations! You've successfully created AWS resources using Crossplane Compositions and verified that your application is working correctly with these resources. This demonstrates the power of using Crossplane to manage cloud resources directly from your Kubernetes cluster.
