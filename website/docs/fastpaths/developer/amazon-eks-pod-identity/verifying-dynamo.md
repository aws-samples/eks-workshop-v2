---
title: "Verifying DynamoDB access"
sidebar_position: 35
---

Now, with the `carts` Service Account associated with the authorized IAM role, the `carts` Pod has permission to access the DynamoDB table. Access the web store again and navigate to the shopping cart.

```bash
$ ALB_HOSTNAME=$(kubectl get ingress ui-auto -n ui -o yaml | yq .status.loadBalancer.ingress[0].hostname)
$ echo "http://$ALB_HOSTNAME"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

The `carts` Pod is able to reach the DynamoDB service and the shopping cart is now accessible!

![Cart](/img/sample-app-screens/shopping-cart.webp)

After the AWS IAM role is associated with the Service Account, any newly created Pods using that Service Account will be intercepted by the [EKS Pod Identity webhook](https://github.com/aws/amazon-eks-pod-identity-webhook). This webhook runs on the Amazon EKS cluster's control plane and is fully managed by AWS. Take a closer look at the new `carts` Pod to see the new environment variables:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

Notable points about these environment variables:

- `AWS_DEFAULT_REGION` - The region is set automatically to the same as our EKS cluster
- `AWS_STS_REGIONAL_ENDPOINTS` - Regional STS endpoints are configured to avoid putting too much pressure on the global endpoint in `us-east-1`
- `AWS_CONTAINER_CREDENTIALS_FULL_URI` - This variable tells AWS SDKs how to obtain credentials using the [HTTP credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html). This means that EKS Pod Identity does not need to inject credentials via something like an `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` pair, and instead the SDKs can have temporary credentials vended to them via the EKS Pod Identity mechanism. You can read more about how this functions in the [AWS documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).

You have successfully configured Pod Identity in your application.
