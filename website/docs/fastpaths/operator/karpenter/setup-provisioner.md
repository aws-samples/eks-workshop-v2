---
title: "Inspect Karpenter configuration"
sidebar_position: 30
---

EKS Auto Mode provides fully-managed Karpenter as an out-of-the-box functionality. Karpenter configuration comes in the form of a `NodePool` CRD (Custom Resource Definition). A single Karpenter `NodePool` is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one `NodePool`, but for the moment we'll use the default node pools that Auto Mode configures for you.

One of the main objectives of Karpenter is to simplify the management of capacity. If you're familiar with other auto scaling solutions, you may have noticed that Karpenter takes a different approach, referred to as **group-less auto scaling**. Other solutions have traditionally used the concept of a **node group** as the element of control that defines the characteristics of the capacity provided (i.e: On-Demand, EC2 Spot, GPU Nodes, etc) and that controls the desired scale of the group in the cluster. In AWS the implementation of a node group matches with [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). Karpenter allows us to avoid complexity that arises from managing multiple types of applications with different compute needs.

We'll start by inspecting the existing resources used by Karpenter. First we'll check out the default `NodePool` that defines general capacity requirements:

```bash 
$ kubectl get nodepools general-purpose -o yaml

apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  annotations:
    karpenter.sh/nodepool-hash: "4012513481623584108"
    karpenter.sh/nodepool-hash-version: v3
  generation: 1
  labels:
    app.kubernetes.io/managed-by: eks
  name: general-purpose
  resourceVersion: "57384"
spec:
  disruption:
    budgets:
    - nodes: 10%
    consolidateAfter: 30s
    consolidationPolicy: WhenEmptyOrUnderutilized
  template:
    metadata: {}
    spec:
      expireAfter: 336h
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: default
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values:
        - on-demand
      - key: eks.amazonaws.com/instance-category
        operator: In
        values:
        - c
        - m
        - r
      - key: eks.amazonaws.com/instance-generation
        operator: Gt
        values:
        - "4"
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
      - key: kubernetes.io/os
        operator: In
        values:
        - linux
      terminationGracePeriod: 24h0m0s
```

In addition to this default `NodePool` resource, you may also create your custom `NodePool` resources to specify different isolation and infrastructure requirements for your workloads. Following are some the key considerations for the same.

1. The `NodePool` is configured to start all new nodes with a Kubernetes label `type: karpenter`, which will allow us to specifically target Karpenter nodes with pods for demonstration purposes.
2. The [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) supports defining node properties like instance type and zone. In this configuration, we're setting the `karpenter.sh/capacity-type` to initially limit Karpenter to provisioning On-Demand instances, as well as `node.kubernetes.io/instance-type` to limit to a subset of specific instance types. You can learn which other properties are [available here](https://karpenter.sh/docs/concepts/scheduling/#selecting-nodes). We'll work on a few more during the workshop.
3. A `NodePool` can define a limit on the amount of CPU and memory managed by it. Once this limit is reached, Karpenter will not provision additional capacity associated with that particular `NodePool`, providing a cap on the total compute.

In addition to `NodePool`, Karpenter also has one more important resource, a `NodeClass`. You can see a `NodeClass` referenced in the previous `NodePool` configuration under `nodeClassRef`. This `NodeClass` is also pre-provisioned by EKS Auto Mode. Here is the configuration of the same.

```bash
$ kubectl get nodeclass default -o yaml

apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  annotations:
    eks.amazonaws.com/nodeclass-hash: "495408067366721138"
    eks.amazonaws.com/nodeclass-hash-version: v2
  finalizers:
  - eks.amazonaws.com/termination
  generation: 1
  labels:
    app.kubernetes.io/managed-by: eks
  name: default
  resourceVersion: "304263"
spec:
  ephemeralStorage:
    iops: 3000
    size: 80Gi
    throughput: 125
  networkPolicy: DefaultAllow
  networkPolicyEventLogs: Disabled
  role: eks-workshop-auto-auto-node
  securityGroupSelectorTerms:
  - id: sg-0c70efd097a74a4cf
  snatPolicy: Random
  subnetSelectorTerms:
  - id: subnet-096bfe6623a87be3f
  - id: subnet-09e84ab4eee5d16bb
  - id: subnet-02a87ab5b226b952d
```

1. The `role` attribute assigns the IAM role that will be applied to the EC2 instance provisioned by Karpenter
2. The `subnetSelectorTerms` can be used to look up the subnets where Karpenter should launch the EC2 instances. 
3. The `securityGroupSelectorTerms` accomplishes the same function for the security group that will be attached to the EC2 instances.

With all these resources managed by EKS Auto Mode, Karpenter has the basic requirements it needs to start provisioning capacity for our cluster.

Let's do some hands-on to see how it works.
