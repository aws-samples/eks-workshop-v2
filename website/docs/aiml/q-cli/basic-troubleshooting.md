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

```bash test=false
$ q chat
```

Ask Q CLI to help troubleshoot the issue by entering the following question:

```text
I have a pod stuck in a pending state in my eks-workshop cluster. Find the cause of the failure and provide me with a summary of the approach to solve it.
```

To address the prompt Q CLI will use a variety of tools from the MCP server. Some of the steps it may take include:

- Identifying the failing pod in the cluster using the `list_k8s_resources` tool
- Fetch details of a pod using the `manage_k8s_resource` tool
- Inspect Kubernetes event history for the pod using `get_k8s_events` tool
- Fetch details of related Kubernetes resources using `manage_k8s_resource` tool
- Pull and refer EKS troubleshooting guide using `search_eks_troubleshoot_guide` tool

Q CLI will provide an analysis based on the data it gather from the cluster.

<details>
  <summary>Expand for sample response</summary>

```text
## Pod Pending Issue Summary

Problem: Pod failing-pod in the default namespace is stuck in pending state.

Root Cause: The pod references a PersistentVolumeClaim named my-pvc that doesn't exist.

Error Details:
• Status: Unschedulable
• Message: persistentvolumeclaim "my-pvc" not found
• 0/3 nodes available due to missing PVC

Solutions:
1. Create the missing PVC - Create a PersistentVolumeClaim named my-pvc using the available gp2 StorageClass
2. Remove the volume requirement - Edit the pod to remove the volume mount and PVC reference
3. Delete the pod - If it's a test pod that's no longer needed

Available Resources:
• StorageClass gp2 is available for creating PVCs
• 3 worker nodes are healthy and available

The pod will automatically schedule once the PVC is created or the volume requirement is removed.
```

</details>

To exit the Q CLI session, enter:

```text
/quit
```

Now, remove the failing Pod: 

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```
In the next section, we'll explore a more complex troubleshooting scenario.
