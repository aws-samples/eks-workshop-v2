---
title: "Debugging"
sidebar_position: 90
---

Till now, we were able to apply network policies without issues or errors. But what happens if there are errors or issues? How will we be able to debug these issues?

Amazon VPC CNI provides logs that can be used to debug issues while implementing networking policies. In addition, you can monitor these logs through services such as Amazon CloudWatch, where you can leverage CloudWatch Container Insights that can help you provide insights on your usage related to NetworkPolicy.

Now, let us try implementing an ingress network policy that will restrict access to the 'carts' service component from 'ui' component only, similar to what we did earlier with the 'checkout' service component.

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-carts-ingress-fail-debug.yaml
```

Lets apply this policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-carts-ingress-fail-debug.yaml
networkpolicy.networking.k8s.io/allow-carts-ingress-webservice created
```

And validate it:

<browser url='http://k8s-ui-albui-634ca3fbcb-7612561.us-west-2.elb.amazonaws.com/cart'>
<img src={require('@site/static/img/sample-app-screens/error-500.png').default}/>
</browser>

As you can see, an error-500 page is displayed, which means something went wrong here. The call from the 'ui' component should have succeeded, but instead it failed. To debug this, we can leverage network policy agent logs to see where the issue is.

Network policy agent logs are available by default in the file `/var/log/aws-routed-eni/network-policy-agent.log` on each worker node. We can also configure logs to be sent to Amazon CloudWatch by the CNI plugin, or we can configure the 'fluentbit' agent to send the logs to Amazon CloudWatch as shown in this [user guide](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html#network-policies-troubleshooting).

To enable CloudWatch logging, we need to ensure the VPC CNI addon's IAM role has permissions to log to CloudWatch. We can attach relevant permissions using the below commands:

```bash wait=30
$ ADDON_ROLE_ARN=$(aws eks describe-addon --cluster-name "eks-workshop" --addon-name "vpc-cni" | jq -r '.addon.serviceAccountRoleArn')
$ ADDON_ROLE_NM=$(aws iam list-roles | jq -r ".Roles[] | select(.Arn == \"$ADDON_ROLE_ARN\") | .RoleName")
$ aws iam put-role-policy --role-name $ADDON_ROLE_NM --policy-name "addon.cwlogs.allow" --policy-document '{"Version": "2012-10-17", "Statement": [ { "Sid": "VisualEditor0", "Effect": "Allow", "Action": ["logs:DescribeLogGroups", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*" }]}'
```

Next, we need to enable logging to CloudWatch by updating the VPC CNI addon's configuration using the below command:

```bash
$ aws eks update-addon --cluster-name ${EKS_CLUSTER_NAME} --addon-name "vpc-cni" --configuration-values '{"env":{"ENABLE_PREFIX_DELEGATION":"true", "ENABLE_POD_ENI":"true", "POD_SECURITY_GROUP_ENFORCING_MODE":"standard"},"enableNetworkPolicy": "true", "nodeAgent": { "enableCloudWatchLogs": "true"}}' --service-account-role-arn ${ADDON_ROLE_ARN}
```

Ensure the addon update has completed before proceeding.

<browser url='https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/add-ons/vpc-cni'>
<img src={require('@site/static/img/eks/addon-updating.png').default}/>
</browser>

<browser url='https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/add-ons/vpc-cni'>
<img src={require('@site/static/img/eks/addon-updated.png').default}/>
</browser>

Now that we have enabled logging for the VPC CNI plugin, the logs should be available under the log group '/aws/eks/eks-workshop/cluster'. We can search all the log streams under the log group '/aws/eks/eks-workshop/cluster' to identify the failure cause by searching for the pattern "DIP: Pod IP" and "PolicyVerdict: DENY". We can find the IP of the 'carts' pod using the below command:

```bash test=false
$ kubectl get pod -n carts  -l app.kubernetes.io/name=carts -l app.kubernetes.io/component=service -o json | jq -r '.items[].status.podIP'
XXX.XXX.XXX.XXX
```

Now open the AWS console and navigate to CloudWatch -> Log groups -> /aws/eks/eks-workshop/cluster. Then click on 'Search all log streams'.

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#home:'>
<img src={require('@site/static/img/cloudwatch/cw-main.png').default}/>
</browser>

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups'>
<img src={require('@site/static/img/cloudwatch/cw-loggroup.png').default}/>
</browser>

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups'>
<img src={require('@site/static/img/cloudwatch/cw-loggroup-selected.png').default}/>
</browser>

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups'>
<img src={require('@site/static/img/cloudwatch/cw-loggroup-search.png').default}/>
</browser>

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups'>
<img src={require('@site/static/img/cloudwatch/cw-loggroup-searchresults.png').default}/>
</browser>

You can now search all the log streams for pattern '"DIP: XXX.XXX.XXX.XXX" "PolicyVerdict: DENY"'.

<browser url='https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups'>
<img src={require('@site/static/img/cloudwatch/cw-loggroup-searchresults-deny.png').default}/>
</browser>

As you could see from the results of the search query, calls to 'carts' pod have been denied. From the message's SIP field, we can identify where the denied calls are originating from using the below command.

```bash
$ kubectl get po -A  -o json | jq -r '.items[] | select(.status.podIP == "REPLACE WITH SIP FIELD") | .metadata.name'
ui-XXXX-YYYY
```

As you could see from the output, the denied calls originate from the 'ui' component. On further analysis, we can find that in our network policy, in the ingress section, we just have podSelector and no namespaceSelector. As the namespaceSelector is empty, it will default to the namespace of the network policy, which is 'carts'. Hence, the policy would be interpreted as allowing pods matching the label 'app.kubernetes.io/name: ui' from the 'carts' namespace, resulting in traffic from the ui' component being denied.

Let's fix the network policy and try again.

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-carts-ingress-success-debug.yaml
```

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-carts-ingress-success-debug.yaml
networkpolicy.networking.k8s.io/allow-orders-ingress-webservice configured
```

As you could see, we are now able to navigate to the 'carts' page from the 'home' page, and the issue is fixed.

<browser url='http://k8s-ui-albui-634ca3fbcb-952136118.us-west-2.elb.amazonaws.com/home'>
<img src={require('@site/static/img/sample-app-screens/cart.png').default}/>
</browser>