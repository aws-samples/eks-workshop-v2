---
title: "Debugging"
sidebar_position: 90
---

Till now, we were able to apply network policies without issues or errors. But what happens if there are errors or issues? How will we be able to debug these issues?

Amazon VPC CNI provides logs that can be used to debug issues while implementing networking policies. In addition, you can monitor these logs through services such as Amazon CloudWatch, where you can leverage CloudWatch Container Insights that can help you provide insights on your usage related to NetworkPolicy.

Now, let us try implementing an ingress network policy that will restrict access to the orders' service component from 'ui' component only, similar to what we did earlier with the 'catalog' service component.

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. The `podSelector` targets pods with labels `app.kubernetes.io/name: orders` and `app.kubernetes.io/component: service`
2. The `ingress.from` allows inbound connections only from pods with the label `app.kubernetes.io/name: ui`

Lets apply this policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml
```

And validate it:

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
...
```

As you can see from the outputs, something went wrong here. The call from 'ui' component should have succeeded, but instead it failed. To debug this, we can leverage network policy agent logs to see where the issue is.

Network policy agent logs are available in the file `/var/log/aws-routed-eni/network-policy-agent.log` on each worker node. Lets see if there are any `DENY` statements being logged in that file:

```bash test=false
$ POD_HOSTIP_1=$(kubectl get po --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].spec.nodeName')
$ kubectl debug node/$POD_HOSTIP_1 -it --image=ubuntu
# Run these commands inside the pod
$ grep DENY /host/var/log/aws-routed-eni/network-policy-agent.log | tail -5
{"level":"info","timestamp":"2023-11-03T23:02:17.916Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
{"level":"info","timestamp":"2023-11-03T23:02:18.920Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
{"level":"info","timestamp":"2023-11-03T23:02:20.936Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
$ exit
```

As you could see from the outputs calls from the 'ui' component have been denied. On further analysis, we can find that in our network policy, in the ingress section, we just have podSelector and no namespaceSelector. As the namespaceSelector is empty, it will default to the namespace of the network policy, which is 'orders'. Hence, the policy would be interpreted as allowing pods matching the label 'app.kubernetes.io/name: ui' from the 'orders' namespace, resulting in traffic from the ui' component being denied.

Let's fix the network policy and try again.

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-success-debug.yaml
```

Now check that the 'ui' can connect:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* Connected to orders.orders (172.20.248.36) port 80 (#0)
> GET /orders HTTP/1.1
> Host: orders.orders
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200
...
```

As you could see from the outputs, now the 'ui' component is able to call the 'orders' service component, and the issue is resolved.
