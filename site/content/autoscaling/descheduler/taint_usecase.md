---
title: "Remove Pods Violating NodeTaints"
date: 2022-06-09T00:00:00-03:00
weight: 3
---

`RemovePodsViolatingNodeTaints` strategy makes sure that pods violating NoSchedule taints on nodes are removed. For example there is a pod "podA" with a toleration to tolerate a taint key=value:NoSchedule scheduled and running on the tainted node. If the node's taint is subsequently updated/removed, taint is no longer satisfied by its pod's tolerations and will be evicted.

Node taints can be excluded from consideration by specifying a list of excludedTaints. If a node taint key or key=value matches an excludedTaints entry, the taint will be ignored.

### Deploy the sample App

```bash
kubectl create deployment nginx --image nginx
```

Verify the deployment is in running state

```bash
kubectl get pods -o wide --selector app=nginx
```
Output will look like:
{{< output >}}
NAME                     READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
nginx-6799fc88d8-k46jv   1/1     Running   0          14s   10.14.10.209    ip-10-14-10-225.us-west-2.compute.internal   <none>           <none>
{{< /output >}}

### Taint the node

Lets find the node where the nginx pod is scheduled

```bash
export FIRST_NODE_NAME=$(kubectl get pods -l app=nginx -o json | jq -r '.items[0].spec.nodeName')
echo $FIRST_NODE_NAME
```

Output will look like:

{{< output >}}
ip-10-14-10-225.us-west-2.compute.internal
{{< /output >}}

Now, apply the  `dedicated=team1` taint to the node.

```bash
# add the taint to the node
kubectl taint nodes ${FIRST_NODE_NAME} dedicated=team1:NoSchedule
```

Output will look like:
{{< output >}}
node/ip-10-14-10-225.us-west-2.compute.internal tainted
{{< /output >}}

We can verify that it worked by re-running the `kubectl describe node` command.

```bash
kubectl describe node $FIRST_NODE_NAME | grep Taint
```

Output will look like:

{{< output >}}
Taints:             dedicated=team1:NoSchedule
{{< /output >}}


Descheduler will evict the nginx pod in the next run as it no longer tolerate the new taint applied to the node. Once evicted, kube-scheduler will kick in and schedule the pod to an untained node.

```bash
kubectl get pods -o wide
```

Output will look like:

{{< output >}}
NAME                     READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
nginx-6799fc88d8-8zss2   1/1     Running   0          16s   10.14.11.252   ip-10-14-11-249.us-west-2.compute.internal   <none>           <none>
{{< /output >}}

Notice the `Node` is changed in the above output. You can also look at the descheduler logs for more analysis

```bash
kubectl logs -n kube-system deployment/descheduler
```

{{< output >}}
I0609 18:40:23.334236       1 node_taint.go:108] "Processing node" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.334389       1 node_taint.go:121] "Not all taints with NoSchedule effect are tolerated after update for pod on node" pod="default/nginx-6799fc88d8-k46jv" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.353289       1 evictions.go:163] "Evicted pod" pod="default/nginx-6799fc88d8-k46jv" reason="NodeTaint" strategy="NodeTaint" node="ip-10-14-10-225.us-west-2.compute.internal"
I0609 18:40:23.353420       1 node_taint.go:108] "Processing node" node="ip-10-14-11-249.us-west-2.compute.internal"
I0609 18:40:23.353525       1 node_taint.go:108] "Processing node" node="ip-10-14-12-91.us-west-2.compute.internal"
....
I0609 18:40:23.354742       1 event.go:294] "Event occurred" object="default/nginx-6799fc88d8-k46jv" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerNodeTaint"
I0609 18:40:23.354776       1 descheduler.go:304] "Number of evicted pods" totalEvicted=1
{{< /output >}}

