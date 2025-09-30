---
title: "Install the Neuron plugin"
sidebar_position: 20
---

The Neuron device plugin exposes Neuron cores and devices to Kubernetes as a resource, enabling the Kubernetes scheduler to provision nodes requiring Neuron acceleration. We'll install the plugin with the [Neuron device plugin Helm chart](https://gallery.ecr.aws/neuron/neuron-helm-chart):

```bash
$ helm upgrade --install neuron-helm-chart oci://public.ecr.aws/neuron/neuron-helm-chart \
  --namespace kube-system --version 1.3.0 \
  --values ~/environment/eks-workshop/modules/aiml/chatbot/neuron-values.yaml \
  --wait
```

This properly exposes the Neuron cores and grants Karpenter the appropriate permissions to provision pods demanding accelerated workloads.

We can verify the DaemonSet has been created:

```bash
$ kubectl get ds neuron-device-plugin -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
neuron-device-plugin   0         0         0       0            0           <none>          10s
```

Since we don't have any compute nodes in our cluster that provide Neuron devices there are no Pods running.
