---
title: "Fixing Tag Issue OLD"
sidebar_position: 30
---

The task for you in this troubleshooting scenario is to investigate the deployment for AWS Load Balancer Controller as well as the ingress object created by following the prompts with the script. At the end of this session, you should be able to see the ui app on your EKS cluster using ALB ingress through the browsers as depicted in the image.

![ingress](./assets/ingress.webp)

## Let's start the troubleshooting

### Step 1

First, we need to verify the status of our pods and get ingress for ingress object creation. To do so, we will use `kubectl` tool.

```bash
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-68495c748c-jkh2z   1/1     Running   0          85s
```

### Step 2

In _Step 1_, we checked the pods status for our application and aws-load-balancer-controller. The _aws-load-balancer-controller_ deployment is responsible for ALB creation for any ingress objects applied to the cluster.

Upon looking for ingress object, did you observe any ALB DNS name to access your application with the ingress object? You can also verify ALB creation in the AWS Management Console. In a successful installation scenario, the ingress object should have an ALB DNS name shown like the example below. However in this case, the ADDRESS section where the ALB DNS should have populated is empty.

```bash
$ kubectl get ingress/ui -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      105s

#---This is the expected output when the ingress was deployed correctly--
NAME           CLASS    HOSTS   ADDRESS                                                                   PORTS   AGE
ingress-2048   <none>   *       k8s-ui-ingress2-xxxxxxxxxx-yyyyyyyyyy.region-code.elb.amazonaws.com   80      2m32s
```

### Step 3

Check further into the ingress for any events indicating why we do not see the ALB DNS. You can retrieve those logs by running the following command. The event logs should point you towards what the issue might be with ingress creation.

```bash
$ kubectl describe ingress/ui -n ui
Name:             ui
Labels:           <none>
Namespace:        ui
Address:
Ingress Class:    alb
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /   service-ui:80 (<error: endpoints "service-ui" not found>)
Annotations:  alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/target-type: ip
Events:
  Type     Reason            Age                    From     Message
  ----     ------            ----                   ----     -------
  Warning  FailedBuildModel  2m23s (x16 over 5m9s)  ingress  Failed build model due to couldn't auto-discover subnets: unable to resolve at least one subnet (0 match VPC and tags: [kubernetes.io/role/elb])

```

Refer the documentation on prerequisites for setting up [ALB with EKS](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/subnet_discovery/)

### Step 4

_Step 3_ points to issues with the subnet auto-discovery for load balancer controller deployment. Ensure that all the public subnets have correct tags `tag:kubernetes.io/role/elb,Values=1'`

:::info
Keep in mind that public subnet means the route table for the subnet has an Internet Gateway allowing traffic to and from the internet.
:::

**1** To find the all subnets through the command line, filter through existing ones with the following tag "Key: `alpha.eksctl.io/cluster-name` Value: `${EKS_CLUSTER_NAME}`". There should be four subnets. **Note:** _For your convenience we have added the cluster name as env variable with the variable `$EKS_CLUSTER_NAME`._

```bash
$ aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]'
[
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx"
]
```

**2** Then by adding in the subnet ID into the route tables CLI filter one at a time, `--filters 'Name=association.subnet-id,Values=subnet-xxxxxxxxxxxxxxxxx'`, identify which subnets are public.

```text
aws ec2 describe-route-tables --filters 'Name=association.subnet-id,Values=<ENTER_SUBNET_ID_HERE>' --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]'

```

Here a script that will help to iterate over the list of subnets

```bash
$ for subnet_id in $(aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]' --output text); do echo "Subnect: ${subnet_id}"; aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=${subnet_id}" --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]'; done
```

If the output shows `0.0.0.0/0` route to an Internet gateway ID, this is a public subnet. See below example.

```text
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxxxxxxxxxxxx0470" --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]'
[
    [
        "10.42.0.0/16",
        "local"
    ],
    [
        "0.0.0.0/0",
        "igw-xxxxxxxxxxxxxxxxx"
    ]
]
```

**3** Once you have all the public subnet ID's, describe subnets with the appropriate tag and confirm that the public subnet ID's that you identified are missing. In our case, none of our subnets have the correct tags.

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
[]
```

**4** Then add the correct tags. To help you a little bit, we have added the 3 public subnets to the `env` variables with the names `PUBLIC_SUBNET_1, PUBLIC_SUBNET_2 and PUBLIC_SUBNET_3`

```text
aws ec2 create-tags --resources subnet-xxxxxxxxxxxxxxxxx subnet-xxxxxxxxxxxxxxxxx subnet-xxxxxxxxxxxxxxxxx --tags 'Key="kubernetes.io/role/elb",Value=1'

```

```bash
$ aws ec2 create-tags --resources $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 $PUBLIC_SUBNET_3 --tags 'Key="kubernetes.io/role/elb",Value=1'
```

**5** Confirm the tags are created. You should see the public subnet ID's populated following the command below.

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
[
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-xxxxxxxxxxxxxxxxx"
]
```

**6** Now restart the controller deployment using the kubectl rollout restart command:

```bash timeout=180
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
deployment.apps/aws-load-balancer-controller restarted
```

**7** Now, check again the ingress deployment:

```bash expectError=true timeout=180 hook=fix-1 hookTimeout=600
$ kubectl describe ingress/ui -n ui
  Warning  FailedDeployModel  68s  ingress  Failed deploy model due to AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action
  status code: 403, request id: b862fb9c-480b-44b5-ba6f-426a3884b6b6
  Warning  FailedDeployModel  26s (x5 over 66s)  ingress  (combined from similar events): Failed deploy model due to AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action
  status code: 403, request id: 197cf2f7-2f68-44f2-92ae-ff5b36cb150f
```

:::tip
In AWS generally for creation/deletion/update of any resource, you will observe a corresponding API call which are recorded in CloudTrail. Look for any CloudTrail events for CreateLoadBalancer API calls. Do you observe any such calls in the last 1 hour of this lab setup?
:::