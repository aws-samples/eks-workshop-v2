---
title: "IP mode"
sidebar_position: 40
---

As mentioned previously, the NLB we have created is operating in "instance mode". Instance target mode supports pods running on AWS EC2 instances. In this mode, AWS NLB sends traffic to the instances and the `kube-proxy` on the individual worker nodes forward it to the pods through one or more worker nodes in the Kubernetes cluster.

However, the AWS Load Balancer Controller also supports creating NLBs operating in "IP mode", In this mode, the AWS NLB targets traffic directly to the Kubernetes pods behind the service, eliminating the need for an extra network hop through the worker nodes in the Kubernetes cluster. IP target mode supports pods running on both AWS EC2 instances and AWS Fargate.

There are several reasons why we might want to configure the NLB to operate in IP target mode:
1. It creates a more efficient network path for inbound connections, bypassing `kube-proxy` on the EC2 worker node
2. This in turn removes the need to consider aspects such as `externalTrafficPolicy` and the trade-offs of its various configuration options
3. An application is running on Fargate instead of EC2

### Re-configuring the NLB

Lets reconfigure our NLB to use IP mode and look at the effect it has on the infrastructure.

This is the patch we'll be applying to re-configure the `Service`:

```file
exposing/load-balancer/ip-mode/nlb.yaml
```

Apply the manifest with kustomize:

```bash
kubectl apply -k /workspace/modules/exposing/load-balancer/ip-mode
```

It will take a few minutes for the configuration of the load balancer to be updated.