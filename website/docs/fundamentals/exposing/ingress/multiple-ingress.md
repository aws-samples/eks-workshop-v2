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
$ kubectl kustomize ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress | envsubst | kubectl apply -f -
ingress.networking.k8s.io/catalog-multi created
ingress.networking.k8s.io/ui-multi created
```

We'll now have two additional Ingress objects in our cluster that end with `-multi`:

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME            CLASS   HOSTS   ADDRESS                                                                PORTS   AGE
catalog     catalog-multi   alb     *       k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com   80      4m6s
ui          ui-multi        alb     *       k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com   80      4m6s
```

Notice that the `ADDRESS` of both are the same URL, which is because both of these Ingress objects are being grouped together behind the same ALB.

We can take a look at the ALB listener to see how this works:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
{
    "Rules": [
        {
            [...]
            "Priority": "1",
            "Conditions": [
                {
                    "Field": "path-pattern",
                    "Values": [
                        "/catalog",
                        "/catalog/*"
                    ],
                    [...]
                }
            ],
            "Actions": [
                {
                    "Type": "forward",
                    "TargetGroupArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/k8s-catalog-catalog-dd063e5d63/0ca7a01dcfe0e890",
                    [...]
                }
            ],
            "IsDefault": false,
            [...]
        },
        {
            [...]
            "Priority": "2",
            "Conditions": [
                {
                    "Field": "path-pattern",
                    "Values": [
                        "/*"
                    ],
                    [...]
                }
            ],
            "Actions": [
                {
                    "Type": "forward",
                    "TargetGroupArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/k8s-ui-ui-a01d749064/e15407cbc96752aa",
                    [...]
                }
            ],
            "IsDefault": false,
            [...]
        },
        {
            [...]
            "Priority": "default",
            "Conditions": [],
            "Actions": [
                {
                    "Type": "fixed-response",
                    "Order": 1,
                    "FixedResponseConfig": {
                        "StatusCode": "404",
                        "ContentType": "text/plain"
                    }
                }
            ],
            "IsDefault": true,
            [...]
        }
    ]
}
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
curl: (6) Could not resolve host: k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com
Warning: Problem : timeout. Retrying in 15 seconds. 30 retries left.
[...]
HTTP/1.1 200 OK
Date: Sat, 31 Oct 2026 14:06:39 GMT
Content-Type: text/html
Content-Length: 19973
Connection: keep-alive
Content-Language: en-US
set-cookie: SESSIONID=5a80431f-672b-4b2e-9afc-b305b332e067
```

Try accessing the new Ingress URL in the browser as before to check the web UI still works:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com
```

Now try accessing a path we directed to the catalog service:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl $ADDRESS/catalog/products | jq .
[
  {
    "id": "a1258cd2-176c-4507-ade6-746dab5ad625",
    "name": "Aqua Ace GT",
    "description": "Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.",
    "price": 10000,
    "tags": [
      {
        "name": "vehicles",
        "displayName": "Vehicles"
      }
    ]
  },
  {
    "id": "d4edfedb-dbe9-4dd9-aae8-009489394955",
    "name": "Audio-Illusion Spinner",
    "description": "Professional-grade sonic illusion generator disguised as a simple yo-yo. Creates realistic sound effects from footsteps to full orchestras. Includes comprehensive training manual and anti-tangle technology.",
    "price": 190,
    "tags": [
      {
        "name": "accessories",
        "displayName": "Accessories"
      }
    ]
  },
  [...]
]
```

You'll receive back a JSON payload from the catalog service, demonstrating that we've been able to expose multiple Kubernetes services via the same ALB.
