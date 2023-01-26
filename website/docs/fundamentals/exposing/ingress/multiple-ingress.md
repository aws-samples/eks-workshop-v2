---
title: "Multiple Ingress pattern"
sidebar_position: 30
---

It's common to leverage multiple Ingress objects in the same EKS cluster, for example to expose multiple different workloads. By default each Ingress will result in the creation of a separate ALB, but we can leverage the IngressGroup feature which enables you to group multiple Ingress resources together. The controller will automatically merge Ingress rules for all Ingresses within IngressGroup and support them with a single ALB. In addition, most annotations defined on an Ingress only apply to the paths defined by that Ingress.

In this example, we'll expose the `catalog` API out through the same ALB as the `ui` component, leveraging path-based routing to dispatch requests to the appropriate Kubernetes service. Let's check we can't already access the catalog API:

```bash expectError=true
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ curl $ADDRESS/catalogue
```

The first thing we'll do is re-create the Ingress for `ui` component adding the annotation `alb.ingress.kubernetes.io/group.name`:

```file
exposing/ingress/multiple-ingress/ingress-ui.yaml
```

Now, let's create a separate Ingress for the `catalog` component that also leverages the same `group.name`:

```file
exposing/ingress/multiple-ingress/ingress-catalog.yaml
```

This ingress is also configuring rules to route requests prefixed with `/catalogue` to the `catalog` component.

Apply these manifests to the cluster:

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k /workspace/modules/exposing/ingress/multiple-ingress
```

We'll now have two separate Ingress objects in our cluster:

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME      CLASS   HOSTS   ADDRESS                                                              PORTS   AGE
catalog     catalog   alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui          ui        alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
```

Notice that the `ADDRESS` of both are the same URL, which is because both of these Ingress objects are being grouped together behind the same ALB.

We can take a look at the ALB listener to see how this works:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

The output of this command will illustrate that:

* Requests with path prefix `/catalogue` will get sent to a target group for the catalog service
* Everything else will get sent to a target group for the ui service
* As a default backup there is a 404 for any requests that happen to fall through the cracks

You can also checkout out the new ALB configuration in the AWS console:

https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName

To wait until the load balancer has finished provisioning you can run this command:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Try accessing the new Ingress URL in the browser as before to check the web UI still works:

```bash
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

Now try accessing the specific path we directed to the catalog service:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ curl $ADDRESS/catalogue | jq .
```

You'll receive back a JSON payload from the catalog service, demonstrating that we've been able to expose multiple Kubernetes services via the same ALB.
