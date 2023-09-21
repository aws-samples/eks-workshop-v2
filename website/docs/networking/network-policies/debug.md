---
title: "Debugging"
sidebar_position: 90
---

Till now, we were able to apply network policies without issues or errors. But what happens if there are errors or issues? How will we be able to debug these issues?

Amazon VPC CNI provides logs that can be used to debug issues while implementing networking policies. In addition, you can monitor these logs through services such as Amazon CloudWatch, where you can leverage CloudWatch Container Insights that can help you provide insights on your usage related to NetworkPolicy.

Now, let us try implementing an ingress network policy that will restrict access to the orders' service component from 'ui' component only, similar to what we did earlier with the 'catalog' service component..
```file
manifests/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml
```
```bash wait=30 timeout=240
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml
```
Let us validate the network policy.
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-5dfb7d65fc-r7gc5
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
...
```
As you could see from the outputs, something went wrong here. The call from 'ui' component should have succeeded, but instead it failed. To debug this, we can leverage network policy agent logs to see where the issue is.


Network policy agent logs are available in the file '/var/log/aws-routed-eni/network-policy-agent.log' for each node.
Let us see if there are any DENY statements being logged in the '/var/log/aws-routed-eni/network-policy-agent.log' log file.
```bash
$ POD_HOSTIP_1=$(kubectl get po --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].status.hostIP')
$ echo $POD_HOSTIP_1
XXX.XXX.XXX.XXX
$ POD_HOST_INSTANCE_1=$(aws ec2 describe-instances --filter Name=network-interface.addresses.private-ip-address,Values=$POD_HOSTIP_1 --query 'Reservations[].Instances[].InstanceId' --output text)
$ echo $POD_HOST_INSTANCE_1
i-xxxxxxxxxxxxxxxxx
$ RUN_COMMAND_ID_1=$(aws ssm send-command --instance-ids $POD_HOST_INSTANCE_1 --document-name "AWS-RunShellScript" --comment "check for network policy agent deny logs" --parameters commands="grep DENY /var/log/aws-routed-eni/network-policy-agent.log | tail -5" --output json | jq -r '.Command.CommandId')
$ echo $RUN_COMMAND_ID_1
$ aws ssm list-command-invocations --command-id $RUN_COMMAND_ID_1 --details | jq -r '.CommandInvocations[0].CommandPlugins[0].Output'
```
As you could see from the outputs, calls from the 'ui' component have been denied. On further analysis, we can find that in our network policy, in the ingress section, we just have podSelector and no namespaceSelector. As the namespaceSelector is empty, it will default to the namespace of the network policy, which is 'orders'. Hence, the policy would be interpreted as allowing pods matching the label 'app.kubernetes.io/name: ui' from the 'orders' namespace, resulting in traffic from the ui' component being denied.
Let's fix the network policy and try again.
```file
manifests/modules/networking/network-policies/apply-network-policies/allow-order-ingress-success-debug.yaml
```
```bash wait=30 timeout=240
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-success-debug.yaml
```
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v orders.orders/orders --connect-timeout 5
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