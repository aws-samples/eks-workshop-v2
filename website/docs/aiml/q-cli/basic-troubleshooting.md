---
title: "Basic Troubleshooting"
sidebar_position: 22
---

In this section we will use Amazon Q CLI and the [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) to troubleshoot issues in the EKS cluster. 

:::caution
You should have Amazon Q CLI with Amazon EKS MCP server configured in your environment for this lab. If that is not the case, please complete [Amazon Q CLI Setup](q-cli-setup.md) lab before you proceed for this lab.
:::

Let's first deploy a failing pod in your cluster. Then we will troubleshoot the problem using Amazon Q CLI.

::yaml{file="manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml
```

Run the following command to find the pod in your cluster in pending status.

```bash
$ kubectl get pods -n default 
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

As you can see, there is a pending pod in the cluster and we don't know what is the cause. Let's ask Q CLI about it.

Run the following command to start a new Q CLI session.

```bash
$ q chat
```

Ask the following question to Q CLI to troubleshoot this issue.

```text
I have a failing pod in my eks-workshop cluster. Please find the cause of the failure and let me know how to solve it.
```

As shown in the following screenshot, Q CLI should be able to provide an accurate root cause analysis for the pod being in the pending state. The actual response you get might differ from this though.

![q-cli-eks-rca-analysis](./assets/q-cli-response-3.jpg)

Now, let's end the Q CLI session and clean up this failing pod to see a more complex troubleshooting use case in the next section.

Enter the following command to exit Q CLI session.

```text
/quit
```

Finally, run the following command to delete the failing pod.

```bash
$ kubectl delete -f /eks-workshop/manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```
