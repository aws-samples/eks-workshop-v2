---
title: "Cloud Bursting"
sidebar_position: 20
sidebar_custom_props: { "module": false }
weight: 30 # used by test framework
---

Building on our previous deployment, we'll now explore a scenario that simulates a "cloud bursting" use case. This will demonstrate how workloads running on EKS Hybrid Nodes can "burst" to EC2 nodes, using elastic cloud capacity during peak demand.

We'll deploy a new workload that, like our previous example, uses `nodeAffinity` to prefer our hybrid nodes. The `preferredDuringSchedulingIgnoredDuringExecution` strategy tells Kubernetes
to _prefer_ our Hybrid Node when scheduling but _ignore_ that during execution.
This means that when there is no more room on our single hybrid node, these pods
are free to schedule elsewhere in the cluster, meaning our EC2 instances. Which
is great! That gives us our cloud bursting we wanted. However, the
_IgnoredDuringExecution_ part means that when we scale back down, Kubernetes
will randomly remove pods and not worry about where they are running, because
that is _ignored during execution_. Generally speaking, Kubernetes will remove
older pods first, which would be the pods running on our Hybrid Nodes. We don't
want that!

We're going to deploy [Kyverno](https://kyverno.io/), which is a policy engine
for Kubernetes. Kyverno will be setup with a policy that watches for Pods that
get scheduled to hybrid nodes (which have been labeled `eks.amazonaws.com/compute-type: hybrid`), and will add an Annotation to that running
pod. The
[controller.kubernetes.io/pod-deletion-cost](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost)
annotation effectively tells Kubernetes to delete less _expensive_ pods first.

Let's get to work. We'll use Helm to install Kyverno and then deploy the policy included below.

```bash timeout=300 wait=30
$ helm repo add kyverno https://kyverno.github.io/kyverno/
$ helm install kyverno kyverno/kyverno --version 3.3.7 -n kyverno --create-namespace -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/values.yaml

```

The `ClusterPolicy` manifest below tells Kyverno to watch for pods that
land on our EKS Hybrid Nodes instance, and adds the `pod-deletion-cost`
annotation to them.

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml" paths="spec.rules.0.match, spec.rules.0.context.0, spec.rules.0.context.1, spec.rules.0.preconditions, spec.rules.0.mutate"}

1. Watch for `Pod/binding` resources, at which point Pod has been scheduled to a Node
2. Set `node` variable with corresponding value from admission review request
3. Set `computeType` variable by querying Kubernetes API for information about the Node to which Pod has been scheduled
4. Only select Pods that have been scheduled to 'hybrid' nodes
5. Modify the Pod to add the `pod-deletion-cost` annotation

Let's apply that now.

```bash timeout=300 wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/policy.yaml
```

Before we can test our workload, we need to make wait for Kyverno to be up and
running so it can enforce the policy we just set up.

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready pods --all -n kyverno --timeout=2m
```

Now we'll deploy our sample workload. This will use the nodeAffinity rules discussed earlier to land 3 nginx pods on our hybrid node.

```bash timeout=300 wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/deployment.yaml
```

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/deployment.yaml"}

After that deployment rolls out we see three nginx-deployment pods, all deployed
to our hybrid node. We're using a custom output from kubectl so we can see the
node and annotations all in one view. We see that Kyverno has applied our
`pod-deletion-cost` annotation!

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```

Let's scale up and burst into the cloud! The nginx deployment here is requesting
an unreasonable amount of CPU (200m) for demonstration purposes. This means we
can fit about 8 replicas on our hybrid node. When we scale up to 15 replicas of
the pod, there is no room to schedule them. Given that we are using the
`preferredDuringSchedulingIgnoredDuringExecution` affinity policy, this means
that we start with our hybrid node. Anything that is unschedulable is allowed to
be scheduled elsewhere (our cloud instances).

Usually scaling would be automatic based on CPU, Memory, GPU availability, or a
external factors like queue depth. Here, we're just going to force the scale
up.

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 15
```

Now when we run `kubectl get pods`, with our custom columns, we see that our
extras have been deployed onto the EC2 instances attached to our workshop EKS
cluster. Kyverno has applied our `pod-deletion-cost` annotation to all of the
pods that landed on our hybrid node, and left it off of all of the Pods that
landed on EC2. When we scale back down, Kubernetes will delete all the _cheap_
Pods first, Pods that have no cost on them. Kubernetes will then see all the
others as equal and the normal deletion logic kicks in. Let's see that in action
now.

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                                          ANNOTATIONS
nginx-deployment-7474978d4f-8269p   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-8f6cg   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-bjbvx   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-f55rj   ip-10-42-108-174.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-jrcsl   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-mstwv   ip-10-42-154-155.us-west-2.compute.internal   <none>
nginx-deployment-7474978d4f-q8nkj   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-smc9f   ip-10-42-163-36.us-west-2.compute.internal    <none>
nginx-deployment-7474978d4f-ss76l   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-tbzf2   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-txxlw   mi-0ebe45e33a53e04f2                          map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-wqbsd   ip-10-42-154-155.us-west-2.compute.internal   <none>
```

Let's scale our sample deployment back down to 3 again. We'll be left with three pods running on our hybrid node, which brings us back to or original state.

```bash timeout=300 wait=30
$ kubectl scale deployment nginx-deployment --replicas 3
```

Finally, just to be sure, let's make sure we're back down to 3 replicas running on our hybrid node.

```bash timeout=300 wait=30
$ kubectl get pods  -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,ANNOTATIONS:.metadata.annotations'
NAME                                NODE                   ANNOTATIONS
nginx-deployment-7474978d4f-9wbgw   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-fjswp   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
nginx-deployment-7474978d4f-k2sjd   mi-0ebe45e33a53e04f2   map[controller.kubernetes.io/pod-deletion-cost:1]
```
