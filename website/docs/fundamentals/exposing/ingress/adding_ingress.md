---
title: "Creating the Ingress"
sidebar_position: 20
---

Lets create an `Ingress` resource with the following manifest:

```file
exposing/ingress/creating-ingress/ingress.yaml
```

This will cause the AWS Load Balancer Controller to provision an Application Load Balancer and configure it to route traffic to the Pods for the `ui` application.

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k /workspace/modules/exposing/ingress/creating-ingress
```

Let's inspect the `Ingress` object created:

```bash
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                            PORTS   AGE
ui     alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      15s
```

Now that our application is exposed to the outside world, lets try to access it.

Get the URL from the `Ingress` resource:

```bash
$ kubectl -n kube-system get ingress -n ui ui -o json | jq \
    -r '.status.loadBalancer.ingress[0].hostname'
k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

And access it in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<browser url='http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com'>
<img src={require('./assets/web-ui.png').default}/>
</browser>

We can take a closer look at the ALB provisioned for this `Ingress` to see how its configured:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/app/k8s-ui-ui-cb8129ddff/f62a7bc03db28e7c",
        "DNSName": "k8s-ui-ui-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com",
        "CanonicalHostedZoneId": "Z1H1FL5HABSF5",
        "CreatedTime": "2022-09-30T03:40:00.950000+00:00",
        "LoadBalancerName": "k8s-ui-ui-cb8129ddff",
        "Scheme": "internet-facing",
        "VpcId": "vpc-0851f873025a2ece5",
        "State": {
            "Code": "active"
        },
        "Type": "application",
        "AvailabilityZones": [
            {
                "ZoneName": "us-west-2b",
                "SubnetId": "subnet-00415f527bbbd999b",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2a",
                "SubnetId": "subnet-0264d4b9985bd8691",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2c",
                "SubnetId": "subnet-05cda6deed7f3da65",
                "LoadBalancerAddresses": []
            }
        ],
        "SecurityGroups": [
            "sg-0f8e704ee37512eb2",
            "sg-02af06ec605ef8777"
        ],
        "IpAddressType": "ipv4"
    }
]
```

What does this tell us?
* The `DNSName` field matches the endpoint displayed by `kubectl get ingress`
* The ALB is accessible over the public internet
* It uses the public subnets in our VPC

You can also inspect the ALB in the console by clicking this link:

https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=ui/ui;sort=loadBalancerName

We can also inspect the targets in the target group that was created by the controller:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.12.225",
                "Port": 8080,
                "AvailabilityZone": "us-west-2c"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "healthy"
            }
        }
    ]
}
```

Since we specified using IP mode in our 'Ingress' object, the target is registered using the IP address of the `ui` pod and the port on which it serves traffic.

You can also take a look at the target group in the console:

https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#TargetGroups:tag:ingress.k8s.aws/stack=ui/ui