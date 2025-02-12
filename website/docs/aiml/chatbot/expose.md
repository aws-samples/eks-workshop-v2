---
title: "Install KubeRay and Neuron Devices"
sidebar_position: 10
---

Before deploying the node pools and Ray Serve Cluster on EKS, it's important to have the necessary tools in place for the workloads to be properly configured.

### Applying KubeRay Operator for Ray Service Cluster

Deploying Ray Cluster on Amazon EKS is supported via the [KubeRay Operator](https://ray-project.github.io/kuberay/), a Kubernetes-native method for managing Ray Clusters. As a module, KubeRay simplifies the deployment of Ray applications by providing three unique custom resource definitions: `RayService`, `RayCluster`, and `RayJob`.

To install the KubeRay Operator, apply the following commands:

```bash
$ helm repo add kuberay https://ray-project.github.io/kuberay-helm/
"kuberay" has been added to your repositories
```

```bash wait=10
$ helm install kuberay-operator kuberay/kuberay-operator --version 1.2.2
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

### Install Neuron Devices

The [Neuron device plugin Kubernetes manifest files](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8) need to be installed into the EKS Cluster to allow Karpenter to properly provision Inferentia-2 instances.

This allows pods to have the resource requirement of `aws.amazon.com/neuron`, enabling the Kubernetes Scheduler to provision a node demanding accelerated machine learning workloads.

:::tip
You can learn more about Neuron Device Plugins in the [AIML Inference module](../../aiml/inferentia/index.md) provided in this workshop.
:::

We can deploy the role using the following command:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin-rbac.yml
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.21.0/src/k8/k8s-neuron-device-plugin.yml

serviceaccount/neuron-device-plugin created
clusterrole.rbac.authorization.k8s.io/neuron-device-plugin created
clusterrolebinding.rbac.authorization.k8s.io/neuron-device-plugin created
daemonset.apps/neuron-device-plugin-daemonset created
```

This properly exposes the Neuron cores and grants Karpenter the appropriate permissions to provision pods demanding accelerated workloads.
