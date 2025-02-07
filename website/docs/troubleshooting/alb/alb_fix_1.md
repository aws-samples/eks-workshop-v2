---
title: "Fixing Tag Issue"
sidebar_position: 30
---

In this troubleshooting scenario, you'll investigate why the AWS Load Balancer Controller isn't creating an Application Load Balancer (ALB) for your ingress resource. By the end of this exercise, you'll be able to access the UI application through an ALB ingress as shown in the image below.

![ingress](./assets/ingress.webp)

## Let's start troubleshooting

### Step 1: Verify Application Status

First, let's verify the status of our UI application:

```bash
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-68495c748c-jkh2z   1/1     Running   0          85s
```

### Step 2: Check Ingress Status

Let's examine the ingress resource. Notice that the ADDRESS field is empty - this indicates the ALB hasn't been created:

```bash
$ kubectl get ingress/ui -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      105s
```

In a successful deployment, you would see an ALB DNS name in the ADDRESS field like this:
```
NAME   CLASS   HOSTS   ADDRESS                                                    PORTS   AGE
ui     alb     *      k8s-ui-ingress-xxxxxxxxxx-yyyyyyyyyy.region.elb.amazonaws.com   80   2m32s
```

### Step 3: Investigate Ingress Events

Let's look at the events associated with the ingress to understand why the ALB creation failed:

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

The error indicates the AWS Load Balancer Controller cannot find any subnets tagged for use with load balancers.

### Step 4: Fix Subnet Tags

The Load Balancer Controller requires public subnets to be tagged with `kubernetes.io/role/elb=1`. Let's identify and tag the correct subnets:

1. Find the cluster's subnets:

```bash
$ aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]'

```

2. Identify which subnets are public by checking their route tables:

```bash
$ for subnet_id in $(aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]' --output text); do
    echo "Subnet: ${subnet_id}"
    aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=${subnet_id}" \
      --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]'
done
```

A public subnet will have a route `0.0.0.0/0` pointing to an Internet Gateway (igw-xxx).

3. Verify current ELB tag status:

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
```

4. Tag the public subnets (we've stored them in environment variables for convenience):

```bash
$ aws ec2 create-tags --resources $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 $PUBLIC_SUBNET_3 \
    --tags 'Key="kubernetes.io/role/elb",Value=1'
```

5. Verify the tags were applied:

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
```

6. Restart the Load Balancer Controller to pick up the new subnet configuration:

```bash
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
```

7. Check the ingress status again:

```bash
$ kubectl describe ingress/ui -n ui
```

The error has changed - now we're seeing an IAM permissions issue that needs to be addressed:

```
Warning  FailedDeployModel  68s  ingress  Failed deploy model due to AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer
```

This indicates we need to fix the IAM permissions for the Load Balancer Controller, which will be addressed in the next section.

:::tip
You can verify ALB creation attempts in CloudTrail by looking for CreateLoadBalancer API calls within the last hour.
:::