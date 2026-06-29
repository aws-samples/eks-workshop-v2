---
title: "Basic troubleshooting"
sidebar_position: 22
---

In this section, we'll use Kiro CLI and the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to troubleshoot issues in the EKS cluster.

Let's start by deploying a failing pod in your cluster, which we'll then troubleshoot using Kiro CLI.

::yaml{file="manifests/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml
```

Check the status of the pod:

```bash
$ kubectl get pods -n default
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

As you can see, there's a pod in a pending state in the cluster. Let's use Kiro CLI to investigate the cause.

Start a new Kiro CLI session:

```bash test=false
$ kiro-cli chat
```

Ask Kiro CLI to help troubleshoot the issue by entering the following question:

```text
I have a pod stuck in a pending state in my eks-workshop cluster. Find the cause of the failure and provide me with a summary of the approach to solve it.
```

To address the prompt Kiro CLI will use a variety of tools from the MCP server. Some of the steps it may take include:

- Identifying the failing pod in the cluster using the `list_k8s_resources` tool
- Fetch details of a pod using the `manage_k8s_resource` tool
- Inspect Kubernetes event history for the pod using `get_k8s_events` tool
- Fetch details of related Kubernetes resources using `manage_k8s_resource` tool
- Pull and refer EKS troubleshooting guide using `search_eks_troubleshoot_guide` tool

Kiro CLI will provide an analysis based on the data it gather from the cluster.

<details>
  <summary>Expand for sample response</summary>

```text
## Summary

Root Cause: The pod failing-pod is stuck in Pending state because it references a PersistentVolumeClaim named my-pvc that doesn't exist.

Error Message: persistentvolumeclaim "my-pvc" not found

Approach to Solve:

1. Create the missing PVC - You need to create a PersistentVolumeClaim named my-pvc in the default namespace with appropriate storage class and size requirements

2. Alternative: Update the pod - If the volume isn't actually needed, remove the volume mount and volume definition from the pod spec and recreate it

3. Verify storage class availability - Before creating the PVC, ensure your cluster has a storage class configured (check with kubectl get storageclass)

The pod cannot be scheduled until the PVC exists because Kubernetes needs to ensure the storage is available before placing the pod on a node.
```

</details>

To exit the Kiro CLI session, enter:

```text
/quit
```

Now, remove the failing Pod: 

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/aiml/kiro-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```
In the next section, we'll explore a more complex troubleshooting scenario.
