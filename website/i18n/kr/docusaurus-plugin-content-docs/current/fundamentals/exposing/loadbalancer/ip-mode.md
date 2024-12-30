---
title: "IP mode"
sidebar_position: 40
---

앞서 언급했듯이, 우리가 생성한 NLB는 "Instance mode"로 작동하고 있습니다. 인스턴스 대상 모드는 AWS EC2 인스턴스에서 실행되는 pod를 지원합니다. 이 모드에서 AWS NLB는 인스턴스로 트래픽을 보내고, 개별 워커 노드의 `kube-proxy`가 Kubernetes 클러스터의 하나 이상의 워커 노드를 통해 pod로 전달합니다.

AWS Load Balancer Controller는 "IP mode"로 작동하는 NLB 생성도 지원합니다. 이 모드에서는 AWS NLB가 서비스 뒤의 Kubernetes pod로 직접 트래픽을 보내므로, Kubernetes 클러스터의 워커 노드를 통한 추가 네트워크 홉이 필요하지 않습니다. IP 대상 모드는 AWS EC2 인스턴스와 AWS Fargate 모두에서 실행되는 pod를 지원합니다.

![IP mode](./assets/ip-mode.webp)

The previous diagram explains how application traffic flows differently when the target group mode is instance and IP.

When the target group mode is instance, the traffic flows via a node port created for a service on each node. In this mode, `kube-proxy` routes the traffic to the pod running this service. The service pod could be running in a different node than the node that received the traffic from the load balancer. ServiceA (green) and ServiceB (pink) are configured to operate in "instance mode".

Alternatively, when the target group mode is IP, the traffic flows directly to the service pods from the load balancer. In this mode, we bypass a network hop of `kube-proxy`. ServiceC (blue) is configured to operate in "IP mode".

The numbers in the previous diagram represents the following things.

1. The EKS cluster where the services are deployed
2. The ELB instance exposing the service
3. The target group mode configuration that can be either instance or IP
4. The listener protocols configured for the load balancer on which the service is exposed
5. The target group rule configuration used to determine the service destination

There are several reasons why we might want to configure the NLB to operate in IP target mode:

1. It creates a more efficient network path for inbound connections, bypassing `kube-proxy` on the EC2 worker node
2. It removes the need to consider aspects such as `externalTrafficPolicy` and the trade-offs of its various configuration options
3. An application is running on Fargate instead of EC2

### Re-configuring the NLB

Let's reconfigure our NLB to use IP mode and look at the effect it has on the infrastructure.

This is the patch we'll be applying to re-configure the Service:

```kustomization
modules/exposing/load-balancer/ip-mode/nlb.yaml
Service/ui-nlb
```

Apply the manifest with kustomize:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/load-balancer/ip-mode
```

It will take a few minutes for the configuration of the load balancer to be updated. Run the following command to ensure the annotation is updated:

```bash
$ kubectl describe service/ui-nlb -n ui
...
Annotations:              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
...
```

You should be able to access the application using the same URL as before, with the NLB now using IP mode to expose your application.

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.183",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        }
    ]
}
```

Notice that we've gone from the 3 targets we observed in the previous section to just a single target. Why is that? Instead of registering the EC2 instances in our EKS cluster the load balancer controller is now registering individual Pods and sending traffic directly, taking advantage of the AWS VPC CNI and the fact that Pods each have a first-class VPC IP address.

Let's scale up the ui component to 3 replicas see what happens:

```bash
$ kubectl scale -n ui deployment/ui --replicas=3
$ kubectl wait --for=condition=Ready pod -n ui -l app.kubernetes.io/name=ui --timeout=60s
```

Now check the load balancer targets again:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.181",
                "Port": 8080,
                "AvailabilityZone": "us-west-2c"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        },
        {
            "Target": {
                "Id": "10.42.140.129",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "10.42.105.38",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        }
    ]
}
```

As expected we now have 3 targets, matching the number of replicas in the ui Deployment.

If you want to wait to make sure the application still functions the same, run the following command. Otherwise you can proceed to the next module.

```bash timeout=240
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```