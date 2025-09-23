---
title: "Multiple Ingress pattern"
sidebar_position: 30
---

It's common to leverage multiple Ingress objects in the same EKS cluster, for example to expose multiple different workloads. By default each Ingress will result in the creation of a separate ALB, but we can leverage the IngressGroup feature which enables you to group multiple Ingress resources together. The controller will automatically merge Ingress rules for all Ingresses within IngressGroup and support them with a single ALB. In addition, most annotations defined on an Ingress only apply to the paths defined by that Ingress.

In this example, we'll expose the `catalog` API out through the same ALB as the `ui` component, leveraging path-based routing to dispatch requests to the appropriate Kubernetes service.

The first thing we'll do is create a new Ingress for the `ui` component:

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-ui.yaml" paths="metadata.annotations,spec.rules.0"}

1. Set the IngressGroup to `retail-app-group` by adding the annotation `alb.ingress.kubernetes.io/group.name`
2. The rules section is used to express how the ALB should route traffic. For the `ui` component we route all HTTP requests where the path starts with `/` to the Kubernetes service called `ui` on port 80


Then we'll create a separate Ingress for the `catalog` component:

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-catalog.yaml" paths="metadata.annotations,spec.rules.0"}

1. To specify the same IngressGroup as the `ui` component set `alb.ingress.kubernetes.io/group.name` to the value `retail-app-group` in the annotations section
2. The rules section is used to express how the ALB should route traffic. For the `catalog` component we route all HTTP requests where the path starts with `/catalog` to the Kubernetes service called `catalog` on port 80

Apply these manifests to the cluster:

```bash wait=60
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress
```

We'll now have two additional Ingress objects in our cluster that end with `-multi`:

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE      NAME      CLASS   HOSTS   ADDRESS                                                              PORTS   AGE
catalog-multi  catalog   alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui-multi       ui        alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui             ui        alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com                     80      4m3s
```

Notice that the `ADDRESS` of both are the same URL, which is because both of these Ingress objects are being grouped together behind the same ALB.

We can take a look at the ALB listener to see how this works:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

The output of this command will illustrate that:

- Requests with path prefix `/catalog` will get sent to a target group for the catalog service
- Everything else will get sent to a target group for the ui service
- As a default backup there is a 404 for any requests that happen to fall through the cracks

You can also check out the new ALB configuration in the AWS console:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

To wait until the load balancer has finished provisioning you can run this command:

```bash timeout=180
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

Try accessing the new Ingress URL in the browser as before to check the web UI still works:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com
```

Now try accessing a path we directed to the catalog service:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl $ADDRESS/catalog/products | jq .
```

You'll receive back a JSON payload from the catalog service, demonstrating that we've been able to expose multiple Kubernetes services via the same ALB.
