---
title: "Basic troubleshooting"
sidebar_position: 22
---

In this section, we'll use Amazon Q CLI and the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to troubleshoot issues in the EKS cluster. 

Let's start by deploying a failing pod in your cluster, which we'll then troubleshoot using Amazon Q CLI.

::yaml{file="manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml
```

Check the status of the pod:

```bash
$ kubectl get pods -n default 
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

As you can see, there's a pod in a pending state in the cluster. Let's use Q CLI to investigate the cause.

Start a new Q CLI session:

```bash
$ q chat
```

Ask Q CLI to help troubleshoot the issue by entering the following question:

```text
I have a failing pod in my eks-workshop cluster. Find the cause of the failure and let me know how to solve it.
```

To address the ask, Q CLI will use different tools from the MCP server. You would see the following high-level steps taken by Q CLI to fulfill the ask as listed in the following Q CLI output snippet.

1. Find the failing pod in the cluster using `list_k8s_resources` tool from EKS MCP server
2. Pull details of a pod using `manage_k8s_resource` tool from EKS MCP server
3. Inspect cluster events for the pod using `get_k8s_events` tool from EKS MCP server
4. Pull details of the persistent volume claim (PVC) referenced in the failing pod using `manage_k8s_resource` tool from EKS MCP server
5. Inspecting cluster events for the PVC using `get_k8s_events` tool from EKS MCP server
6. Describe IAM roles and policies in the scope using `get_policies_for_role` tool from EKS MCP server
7. Pull and refer EKS troubleshooting guide using `search_eks_troubleshoot_guide` tool from EKS MCP server
8. Determine the root cause of the problem using the collected data
9. Suggest corrective action to solve the problem

```text
> I have a failing pod in my eks-workshop cluster. Find the cause of the failure and let me know how to solve it.

> I'll help you diagnose the failing pod in your eks-workshop cluster. Let me start by checking what pods are currently running and identify any that are failing.


🛠️  Using tool: list_k8s_resources from mcp server awslabseks_mcp_server
 ⋮
 ● Running list_k8s_resources with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod"
 ⋮    },
 ⋮    "name": "list_k8s_resources"
 ⋮  }

...
...

> I found a pod named "failing-pod" in the default namespace. Let me get more detailed information about this pod to see its current status and any issues.


🛠️  Using tool: manage_k8s_resource from mcp server awslabseks_mcp_server
 ⋮
 ● Running manage_k8s_resource with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod",
 ⋮      "name": "failing-pod",
 ⋮      "namespace": "default",
 ⋮      "operation": "read"
 ⋮    },
 ⋮    "name": "manage_k8s_resource"
 ⋮  }

...
...

> The pod is in "Pending" status, which indicates it hasn't been scheduled yet. I can see it's trying to mount a PersistentVolumeClaim named "my-pvc". Let me check the events for this pod to get more details about why it's
failing.


🛠️  Using tool: get_k8s_events from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_k8s_events with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "Pod",
 ⋮      "name": "failing-pod",
 ⋮      "namespace": "default"
 ⋮    },
 ⋮    "name": "get_k8s_events"
 ⋮  }

...
...

> No events found for the pod. Let me check if the PersistentVolumeClaim "my-pvc" exists, as this is likely the issue.


🛠️  Using tool: manage_k8s_resource from mcp server awslabseks_mcp_server
 ⋮
 ● Running manage_k8s_resource with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "api_version": "v1",
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "PersistentVolumeClaim",
 ⋮      "name": "my-pvc",
 ⋮      "namespace": "default",
 ⋮      "operation": "read"
 ⋮    },
 ⋮    "name": "manage_k8s_resource"
 ⋮  }

...
...

> The PersistentVolumeClaim exists but is also in "Pending" status. Let me check the events for the PVC to understand why it's not being bound.


🛠️  Using tool: get_k8s_events (trusted) from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_k8s_events with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "cluster_name": "eks-workshop",
 ⋮      "kind": "PersistentVolumeClaim",
 ⋮      "name": "my-pvc",
 ⋮      "namespace": "default"
 ⋮    },
 ⋮    "name": "get_k8s_events"
 ⋮  }

...
...


> Perfect! I found the root cause. The issue is clear from the events - the EKS node group's IAM role doesn't have permission to create EBS volumes. Let me check the current IAM role and its policies.


🛠️  Using tool: get_policies_for_role from mcp server awslabseks_mcp_server
 ⋮
 ● Running get_policies_for_role with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "role_name": "eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-qtnRXmhOqlzR"
 ⋮    },
 ⋮    "name": "get_policies_for_role"
 ⋮  }

...
...

> The AWS token is expired, but I have enough information from the events to diagnose the issue. Let me search the EKS troubleshooting guide for this specific error.


🛠️  Using tool: search_eks_troubleshoot_guide from mcp server awslabseks_mcp_server
 ⋮
 ● Running search_eks_troubleshoot_guide with the param:
 ⋮  {
 ⋮    "arguments": {
 ⋮      "query": "PVC provisioning failed ec2:CreateVolume permission denied node instance role"
 ⋮    },
 ⋮    "name": "search_eks_troubleshoot_guide"
 ⋮  }

...
...

```

You should see a root cause analysis similar to this:

![q-cli-eks-rca-analysis](./assets/q-cli-response-3.jpg)

Now that we've identified the issue, let's clean up. First, exit the Q CLI session:

```text
/quit
```

Then remove the failing pod:

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```

In the next section, we'll explore a more complex troubleshooting scenario.

