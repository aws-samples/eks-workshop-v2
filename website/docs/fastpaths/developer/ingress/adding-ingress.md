---
title: "Creating the Ingress"
sidebar_position: 20
---

:::info AWS Load Balancer Controller
The AWS Load Balancer Controller is included with Amazon EKS Auto Mode and runs in the control plane. It will automatically provision AWS load balancers when you create Ingress resources.
:::

Currently there are no Ingress resources in our cluster, which you can check with the following command:

```bash expectError=true
$ kubectl get ingress -n ui
No resources found in ui namespace.
```

First, we need to configure an IngressClass and IngressClassParams:

::yaml{file="manifests/modules/fastpaths/developers/ingress/adding-ingress/ingressclass.yaml" paths="0.spec.controller,0.spec.parameters,1.spec"}

1. The `controller` field must be set to `eks.amazonaws.com/alb` to target the Auto Mode ALB capability
2. The `parameters` section references an IngressClassParams resource with `apiGroup: eks.amazonaws.com`
3. The IngressClassParams defines AWS-specific configuration like the load balancer scheme and target type

Using this IngressClass we will configure an Ingress:

::yaml{file="manifests/modules/fastpaths/developers/ingress/adding-ingress/ingress.yaml" paths="kind,spec.ingressClassName,spec.rules"}

1. Use an `Ingress` kind
2. The `ingressClassName` references our Auto Mode IngressClass
3. The rules section routes all HTTP requests where the path starts with `/` to the Kubernetes service called `ui` on port 80

Note: With EKS Auto Mode, ALB configuration via annotations is not supported. Configuration must be done in the IngressClassParams.

Let's apply those configurations

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/developers/ingress/adding-ingress/
```

Let's inspect the Ingress object created:

```bash
$ kubectl get ingress ui-auto -n ui
NAME   CLASS          HOSTS   ADDRESS                                                     PORTS   AGE
ui-auto     eks-auto-alb   *       k8s-ui-uiauto-6cd0ef095e-78768930.us-west-2.elb.amazonaws.com   80      5s
```

The ALB will take several minutes to provision and register its targets so take some time to take a closer look at the ALB provisioned for this Ingress to see how its configured:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/app/k8s-ui-uiauto-cb8129ddff/f62a7bc03db28e7c",
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

- The ALB is accessible over the public internet
- It uses the public subnets in our VPC

Inspect the targets in the target group that was created by the controller:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.183",
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

Since we specified using IP mode in our Ingress object, the target is registered using the IP address of the `ui` pod and the port on which it serves traffic.

You can also inspect the ALB and its target groups in the console by clicking this link:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=ui/ui-auto;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

Get the URL from the Ingress resource:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-uiauto-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com
```

To wait until the load balancer has finished provisioning you can run this command:

```bash
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

And access it in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<Browser url="http://k8s-ui-uiauto-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
