---
title: "Verifying DynamoDB Access"
sidebar_position: 50
---

Now, with the `carts` Service Account annotated with the authorized IAM Role, the `carts` Pod has permission to access the DynamoDB table. Access the web store again and navigate to the shopping cart.

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

The `carts` Pod is able to reach the DynamodDB service and the shopping cart is now accessible!

<browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart">
<img src={require('@site/static/img/sample-app-screens/shopping-cart.png').default}/>
</browser>

Let's take a closer look at the new `carts` Pod to see whats happening.

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_ROLE_ARN=arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

These environment variables have not been passed in using something like a ConfigMap or configured directly on the Deployment. Instead these have been set by IRSA automatically to allow AWS SDKs to obtain temporary credentials from the AWS STS service.

Things that are worth noting are:

* The region is set automatically to the same as our EKS cluster
* STS regional endpoints are configured to avoid putting too much pressure on the global endpoint in `us-east-1`
* The role ARN matches the role that we used to annotate our Kubernetes ServiceAccount earlier

Finally, the `AWS_WEB_IDENTITY_TOKEN_FILE` variable tells AWS SDKs how to obtains credentials using web identity federation. This means that IRSA does not need to inject credentials via something like an `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` pair, and instead the SDKs can have temporary credentials vending to them via an OIDC mechanism. You can read more about how this functions in the [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html).
