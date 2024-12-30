---
title: Scheduling on Fargate
sidebar_position: 12
---

So why isn't the `checkout` service already running on Fargate? Let's check its labels:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq '.items[0].metadata.labels'
```

Looks like our Pod is missing the label `fargate=yes`, so lets fix that by updating the deployment for that service so the Pod spec includes the label needed for the profile to schedule it on Fargate.

```kustomization
modules/fundamentals/fargate/enabling/deployment.yaml
Deployment/checkout
```

Apply the kustomization to the cluster:

```bash timeout=220 hook=enabling
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/enabling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

This will cause the Pod specification for the `checkout` service to be updated and trigger a new deployment, replacing all the Pods. When the new Pods are scheduled, the Fargate scheduler will match the new label applied by the kustomization with our target profile and intervene to ensure our Pod is schedule on capacity managed by Fargate.

How can we confirm that it worked? Describe the new Pod thats been created and take a look at the `Events` section:

```bash
$ kubectl describe pod -n checkout -l fargate=yes
[...]
Events:
  Type     Reason           Age    From               Message
  ----     ------           ----   ----               -------
  Warning  LoggingDisabled  10m    fargate-scheduler  Disabled logging because aws-logging configmap was not found. configmap "aws-logging" not found
  Normal   Scheduled        9m48s  fargate-scheduler  Successfully assigned checkout/checkout-78fbb666b-fftl5 to fargate-ip-10-42-11-96.us-west-2.compute.internal
  Normal   Pulling          9m48s  kubelet            Pulling image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0"
  Normal   Pulled           9m5s   kubelet            Successfully pulled image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0" in 43.258137629s
  Normal   Created          9m5s   kubelet            Created container checkout
  Normal   Started          9m4s   kubelet            Started container checkout
```

The events from `fargate-scheduler` give us some insight in to what has happened. The entry we're mainly interested in at this stage in the lab is the event with the reason `Scheduled`. Inspecting that closely gives us the name of the Fargate instance that was provisioned for this Pod, in the case of the above example this is `fargate-ip-10-42-11-96.us-west-2.compute.internal`.

We can inspect this node from `kubectl` to get additional information about the compute that was provisioned for this Pod:

```bash
$ NODE_NAME=$(kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].spec.nodeName')
$ kubectl describe node $NODE_NAME
Name:               fargate-ip-10-42-11-96.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/compute-type=fargate
                    failure-domain.beta.kubernetes.io/region=us-west-2
                    failure-domain.beta.kubernetes.io/zone=us-west-2b
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-42-11-96.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    topology.kubernetes.io/region=us-west-2
                    topology.kubernetes.io/zone=us-west-2b
[...]
```

This provides us with a number of insights in to the nature of the underlying compute instance:

- The label `eks.amazonaws.com/compute-type` confirms that a Fargate instance was provisioned
- Another label `topology.kubernetes.io/zone` specified the availability zone that the pod is running in
- In the `System Info` section (not shown above) we can see that the instance is running Amazon Linux 2, as well as the version information for system components like `container`, `kubelet` and `kube-proxy`
