---
title: "Install KubeRay and Neuron plugin"
sidebar_position: 20
---

Before provisioning the node pools and deploying the Ray Serve cluster on EKS, it's important to have the necessary tools in place for the workloads to be properly configured.

Deploying Ray clusters on Amazon EKS is supported via the [KubeRay Operator](https://ray-project.github.io/kuberay/), a Kubernetes-native method for managing Ray clusters. As a module, KubeRay simplifies the deployment of Ray applications by providing three unique custom resource definitions: `RayService`, `RayCluster`, and `RayJob`.

To install the KubeRay operator, apply the following commands:

```bash
$ helm repo add kuberay https://ray-project.github.io/kuberay-helm/
"kuberay" has been added to your repositories
```

```bash wait=10
$ helm install kuberay-operator kuberay/kuberay-operator \
  --version 1.2.0 --wait
NAME: kuberay-operator
LAST DEPLOYED: Wed Jul 24 14:46:13 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST-SUITE: None
```

Once KubeRay has been properly installed, we can check that it exists under the default namespace:

```bash
$ kubectl get pods
NAME                                READY   STATUS   RESTARTS   AGE
kuberay-operator-6fcbb94f64-mbfnr   1/1     Running  0          17s
```

Next, the Neuron device plugin exposes Neuron cores and devices to Kubernetes as a resource, enabling the Kubernetes scheduler to provision nodes requiring Neuron acceleration. We'll install the plugin with the [Neuron device plugin Kubernetes manifest files](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8).

:::tip
You can learn more about Neuron device plugin in the [AIML Inference module](../../aiml/inferentia/index.md) provided in this workshop.
:::

Deploy the configuration:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.1/src/k8/k8s-neuron-device-plugin-rbac.yml
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.1/src/k8/k8s-neuron-device-plugin.yml

serviceaccount/neuron-device-plugin created
clusterrole.rbac.authorization.k8s.io/neuron-device-plugin created
clusterrolebinding.rbac.authorization.k8s.io/neuron-device-plugin created
daemonset.apps/neuron-device-plugin-daemonset created
```

This properly exposes the Neuron cores and grants Karpenter the appropriate permissions to provision pods demanding accelerated workloads.
