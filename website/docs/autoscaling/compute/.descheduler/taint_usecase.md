---
title: "Node taint use-case"
sidebar_position: 3
---

The `RemovePodsViolatingNodeTaints` strategy makes sure that pods violating NoSchedule taints on nodes are removed. For example there is a pod "podA" with a toleration to tolerate a taint `key=value:NoSchedule` scheduled and running on the tainted node. If the node's taint is subsequently updated/removed, taint is no longer satisfied by its pod's tolerations and will be evicted.

Node taints can be excluded from consideration by specifying a list of excludedTaints. If a node taint key or key=value matches an excludedTaints entry, the taint will be ignored.

# Taint a node

In order to demonstrate this scenario we need to apply a taint to a node. The commands below are going to:
- Identify an arbitrary node
- Taint the node

```bash hook=descheduler-taint
$ export FIRST_NODE_NAME=$(kubectl get nodes --sort-by={metadata.name} --no-headers -l workshop-default=yes -o json | jq -r '.items[0].metadata.name')
$ kubectl taint nodes ${FIRST_NODE_NAME} dedicated=team1:NoSchedule --overwrite
```

The descheduler will evict the all pods on its next reconciliation loop as it does not tolerate the taint applied to the node. Once evicted, `kube-scheduler` will kick in and schedule those pods to an untained node. We can observe this by watching the pods:

```bash
$ kubectl get pods -o wide -l app.kubernetes.io/created-by=eks-workshop -A
```

What we expect to see is that multiple pods will get identified for eviction and terminated, with new pods starting to take their place.

You can also look at the descheduler logs to understand its actions:

```bash
$ kubectl logs -n kube-system deployment/descheduler
I0609 18:40:23.334236       1 node_taint.go:108] "Processing node" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.334389       1 node_taint.go:121] "Not all taints with NoSchedule effect are tolerated after update for pod on node" pod="default/nginx-6799fc88d8-k46jv" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.353289       1 evictions.go:163] "Evicted pod" pod="default/nginx-6799fc88d8-k46jv" reason="NodeTaint" strategy="NodeTaint" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.353420       1 node_taint.go:108] "Processing node" node="ip-10-14-11-249.us-west-2.compute.internal"
I0609 18:40:23.353525       1 node_taint.go:108] "Processing node" node="ip-10-14-12-91.us-west-2.compute.internal"
....
I0609 18:40:23.354742       1 event.go:294] "Event occurred" object="default/nginx-6799fc88d8-k46jv" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerNodeTaint"
I0609 18:40:23.354776       1 descheduler.go:304] "Number of evicted pods" totalEvicted=1
```

Once the exercise is complete remove the taint from the node:

```bash expectError=true
$ kubectl taint nodes -l workshop-default=yes dedicated=team1:NoSchedule-
```
