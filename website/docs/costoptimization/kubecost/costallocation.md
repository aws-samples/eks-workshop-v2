---
title: "Cost Allocation"
sidebar_position: 20
---

Now we will take a look at Cost Allocation. Click on <b>Cost Allocation</b>.

You should see the following Dashboard:

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/costallocation.png').default}/>
</browser>

We can use this screen to dive further into the cost allocation of our cluster. We can look at varous cost dementions:

- namespace
- deployment
- pod
- labels

To do this click on the setting button next to <b>Aggregate by</b> at the top right.

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/costallocation-filter.png').default}/>
</browser>

Then under <b>Filters</b> select <b>label</b> from the drop down menu, enter the value `app.kubernetes.io/instance:kubecost`, and click the plus symbol.

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/costallocation-label.png').default}/>
</browser>

This filters down the namespaces to only show running our workloads that are part of the `kubecost` application.

Now click on <b>Aggregate by</b> and choose <b>Deployment</b>. This will aggregate the costs by deployment intead of by namespace. See below.

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/aggregate-by-deployment.png').default}/>
</browser>

We can also dig deeper into a single namespace. Set <b>Aggregate by</b> back to <b>Namespace</b>, remove the filter, and click on one of the namespaces in the table.

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/namespace.png').default}/>
</browser>

This gives additional information into this namespace.

Click on one of the entries under <b>Controllers</b>.

<browser url='http://localhost:9090/allocations'>
<img src={require('./assets/controllers.png').default}/>
</browser>

This shows us more detail of the specific "controller", in this case a deamonset. We can start to use this information to understand what optimizations we can make. Such as tuning resource requests and limits to limit the amount of CPU and memory that is allocated to each pod in our EKS cluster.

There are many other features available with Kubecost as well, like Savings, Health, Reports and Alerts. Feel free to play around with various links.
