---
title: "Install the Neuron plugin"
sidebar_position: 20
---

For Kubernetes to recognize and effectively utilize AWS Neuron accelerators, we need to install the Neuron device plugin. This plugin is responsible for exposing Neuron cores and devices as schedulable resources within the Kubernetes cluster, allowing the scheduler to appropriately provision nodes with Neuron acceleration when requested by workloads.

The [AWS Neuron SDK](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/) is a software development kit that enables machine learning workloads on AWS Inferentia and Trainium chips. The device plugin is a key component that bridges Kubernetes' resource management capabilities with these specialized accelerators.

Let's install the Neuron device plugin using the official [Neuron device plugin Helm chart](https://gallery.ecr.aws/neuron/neuron-helm-chart):

```bash
$ helm upgrade --install neuron-helm-chart oci://public.ecr.aws/neuron/neuron-helm-chart \
  --namespace kube-system --version 1.3.0 \
  --values ~/environment/eks-workshop/modules/aiml/chatbot/neuron-values.yaml \
  --wait
```

We can verify that the DaemonSet has been created successfully:

```bash
$ kubectl get ds neuron-device-plugin -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
neuron-device-plugin   0         0         0       0            0           <none>          10s
```

Since we don't have any compute nodes in our cluster that provide Neuron devices yet, no Pods are currently running. Once we provision Trainium instances in the next section, the DaemonSet will automatically deploy the device plugin to those nodes, making the Neuron devices available to our workloads.
