---
title: "Updating the application"
sidebar_position: 25
---

When new resources are created or updated, application configurations often need to be adjusted to utilize these new resources. Environment variables are a popular choice for application developers to store configuration, and in Kubernetes, we can pass environment variables to containers through the `env` field of the `container` [spec](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/) when creating deployments.

There are two primary ways to achieve this in Kubernetes:

1. **ConfigMaps**: These are core resources in Kubernetes that allow us to pass configuration elements such as environment variables, text fields, and other items in a key-value format to be used in pod specs.
2. **Secrets**: While not encrypted by default (which is important to remember), secrets are used to store sensitive information like passwords.

For this lab, we'll focus on updating the ConfigMap for the carts component. We'll remove the configuration that points it to the local DynamoDB and instead use the name of the DynamoDB table created by Crossplane:

```kustomization
modules/automation/controlplanes/crossplane/app/kustomization.yaml
ConfigMap/carts
```

Additionally, we need to provide the carts Pods with the appropriate IAM permissions to access the DynamoDB service. An IAM role has already been created, and we'll apply this to the carts Pods using IAM Roles for Service Accounts (IRSA):

```kustomization
modules/automation/controlplanes/crossplane/app/carts-serviceAccount.yaml
ServiceAccount/carts
```

To learn more about how IRSA works, refer to the [official documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

Let's apply this new configuration:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/app \
  | envsubst | kubectl apply -f-
```

Now we need to recycle all the carts Pods to pick up our new ConfigMap contents:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=40s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

To verify that the application is working with the new DynamoDB table, we can use the Network Load Balancer (NLB) that has been created to expose the sample application for testing. This allows us to directly interact with the application through a web browser:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

:::info
Please note that the actual endpoint will be different when you run this command, as a new Network Load Balancer endpoint will be provisioned.
:::

To wait until the load balancer has finished provisioning, you can run this command:

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Once the load balancer is provisioned, you can access it by pasting the URL in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

To verify that the **Carts** module is indeed using the DynamoDB table we just provisioned, try adding a few items to the cart.

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

To check if items are present in the DynamoDB table as well, run:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

Congratulations! You've successfully created and utilized AWS resources without leaving the confines of the Kubernetes API!
