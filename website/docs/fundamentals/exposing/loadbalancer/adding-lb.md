---
title: "Creating the load balancer"
sidebar_position: 20
---

Let's create an additional Service that provisions a load balancer with the following kustomization:

```file
exposing/load-balancer/nlb/nlb.yaml
```

This `Service` will create a Network Load Balancer that listens on port 80 and forwards connections to the `ui` Pods on port 8080. An NLB is a layer 4 load balancer that on our case operates at the TCP layer.

```bash timeout=180 hook=add-lb hookTimeout=430
$ kubectl apply -k /workspace/modules/exposing/load-balancer/nlb
```

Let's inspect the Service resources for the `ui` application again:

```bash
$ kubectl get service -n ui
```

We see two separate resources, with the new `ui-nlb` entry being of type `LoadBalancer`. Most importantly note it has an "external IP" value, this the DNS entry that can be used to access our application from outside the Kubernetes cluster.

The NLB will take several minutes to provision and register its targets so take some time to inspect the load balancer resources the controller has created.

First, take a look at the load balancer itself:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/net/k8s-ui-uinlb-e1c1ebaeb4/28a0d1a388d43825",
        "DNSName": "k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com",
        "CanonicalHostedZoneId": "Z18D5FSROUN65G",
        "CreatedTime": "2022-11-17T04:47:30.516000+00:00",
        "LoadBalancerName": "k8s-ui-uinlb-e1c1ebaeb4",
        "Scheme": "internet-facing",
        "VpcId": "vpc-00be6fc048a845469",
        "State": {
            "Code": "active"
        },
        "Type": "network",
        "AvailabilityZones": [
            {
                "ZoneName": "us-west-2c",
                "SubnetId": "subnet-0a2de0809b8ee4e39",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2a",
                "SubnetId": "subnet-0ff71604f5b58b2ba",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2b",
                "SubnetId": "subnet-0c584c4c6a831e273",
                "LoadBalancerAddresses": []
            }
        ],
        "IpAddressType": "ipv4"
    }
]
```

What does this tell us?

* The NLB is accessible over the public internet
* It uses the public subnets in our VPC

We can also inspect the targets in the target group that was created by the controller:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-06a12e62c14e0c39a",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "i-088e21d0af0f2890c",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "i-0fe2202d18299816f",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        }
    ]
}
```

The output above shows that we have 3 targets registered to the load balancer using the EC2 instance IDs (`i-`) each on the same port. The reason for this is that by default the AWS Load Balancer Controller operates in "instance mode", which targets traffic to the worker nodes in the EKS cluster and allows `kube-proxy` to forward traffic to individual Pods.

You can also inspect the NLB in the console by clicking this link:

https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:service.k8s.aws/stack=ui/ui-nlb;sort=loadBalancerName

Get the URL from the Service resource:

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

To wait until the load balancer has finished provisioning you can run this command:

```bash
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Now that our application is exposed to the outside world, lets try to access it by pasting that URL in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.png').default}/>
</browser>
