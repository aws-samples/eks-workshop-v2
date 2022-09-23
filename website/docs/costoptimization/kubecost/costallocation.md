---
title: "Cost Allocation"
sidebar_position: 20
---

Now we will take a look at Cost Allocation. Click on <b>Cost Allocation</b>.

You should see the following Dashboard:

<browser url='http://localhost:9090/allocations'>
<img src='https://static.us-east-1.prod.workshops.aws/public/94641b58-47d2-4f8c-b66f-34ff8bae69df/static/images/kubecost/cost-allocation.png'/>
</browser>

We can use this screen to dive further into the cost allocation of our cluster. We can look at varous cost dementions:

- namespace
- deployment
- pod
- labels

To do this click on the setting button next to <b>Aggregate by</b> at the top left.

<browser url='http://localhost:9090/allocations'>
<img src='https://static.us-east-1.prod.workshops.aws/public/94641b58-47d2-4f8c-b66f-34ff8bae69df/static/images/kubecost/allocation-options.png'/>
</browser>

Then under <b>Filters</b> select <b>label</b> from the drop down menu and enter the value `app.kubernetes.io/created-by:eks-workshop`.

<browser url='http://localhost:9090/allocations'>
<img src='https://static.us-east-1.prod.workshops.aws/public/94641b58-47d2-4f8c-b66f-34ff8bae69df/static/images/kubecost/label-filter.png'/>
</browser>

This filters down the namespaces to only show running our workloads that have been created by `eks-workshop`.

Now click on <b>Aggregate by</b> and choose <b>Deployment</b>. This will aggregate the costs by deployment intead of by namespace. See below.

<browser url='http://localhost:9090/allocations'>
<img src='https://static.us-east-1.prod.workshops.aws/public/94641b58-47d2-4f8c-b66f-34ff8bae69df/static/images/kubecost/deployments.png'/>
</browser>

We can also dig deeper into a single namespace. Set <b>Aggregate by</b> back to <b>Namespace</b> and click on one of the namespaces in the table. 

<browser url='http://localhost:9090/allocations'>
<img src='https://static.us-east-1.prod.workshops.aws/public/94641b58-47d2-4f8c-b66f-34ff8bae69df/static/images/kubecost/namespace-detail.png'/>
</browser>

This gives additional information into this namespace. 