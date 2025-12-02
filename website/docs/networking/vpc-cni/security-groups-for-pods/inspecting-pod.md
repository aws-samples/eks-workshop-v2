---
title: "Inspecting the Pod"
sidebar_position: 50
---

Now that the catalog Pod is running and successfully using our Amazon RDS database, let's take a closer look at it to see what signals are present related to Security Groups for Pods.

The first thing we can do is check the annotations of the Pod:

```bash
$ kubectl get pod -n catalog -l app.kubernetes.io/component=service -o yaml \
  | yq '.items[0].metadata.annotations'
kubernetes.io/psp: eks.privileged
prometheus.io/path: /metrics
prometheus.io/port: "8080"
prometheus.io/scrape: "true"
vpc.amazonaws.com/pod-eni: '[{"eniId":"eni-0eb4769ea066fa90c","ifAddress":"02:23:a2:af:a2:1f","privateIp":"10.42.10.154","vlanId":2,"subnetCidr":"10.42.10.0/24"}]'
```

The `vpc.amazonaws.com/pod-eni` annotation shows metadata regarding the branch ENI that has been used for this Pod, including its ID, MAC address, private IP address, and subnet CIDR.

The Kubernetes events will also show the VPC resource controller taking action in response to the configuration we added:

```bash
$ kubectl events -n catalog | grep -i SecurityGroupRequested
5m         Normal    SecurityGroupRequested   pod/catalog-6ccc6b5575-w2fvm    Pod will get the following Security Groups [sg-037ec36e968f1f5e7]
```

:::info
The VPC Resource Controller is responsible for managing the lifecycle of branch network interfaces, attaching them to Pods, and associating security groups with them.
:::

You can also view the ENIs managed by the VPC resource controller in the AWS console:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#NIC:v=3;tag:eks:eni:owner=eks-vpc-resource-controller;tag:vpcresources.k8s.aws/trunk-eni-id=:eni" service="ec2" label="Open EC2 console"/>

This will allow you to see information about the branch ENI such as the security group assigned. These branch ENIs are associated with the trunk interface and are dedicated to specific Pods, allowing for fine-grained network security controls at the Pod level.
