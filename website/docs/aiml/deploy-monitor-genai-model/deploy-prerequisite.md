---
title: "Install Nvidia GPU and Ray Operators"
sidebar_position: 20
description: "Install Nvidia GPU and Ray Operators"
---

### Deploy NVIDIA GPU Operator 

The NVIDIA GPU Operator within Kubernetes automate the management of all NVIDIA software components needed to provision GPU. These components include the NVIDIA drivers (to enable CUDA), Kubernetes device plugin for GPUs, the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit), automatic node labelling using [GPU Feature Discovery(GFD)](https://github.com/NVIDIA/gpu-feature-discovery), [Data Center GPU Manager(DCGM)](https://developer.nvidia.com/dcgm) operator export the GPU metrics.


Add the NVIDIA Helm repository and install the GPU Operator:

```bash timeout=300 wait=60 hook=gpu-operator-status-check
$ helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
$ helm repo update
$ helm install --wait --generate-name -n gpu-operator --create-namespace nvidia/gpu-operator
```

Once installed, we should see the node-feature-discovery running on each node, nvidia-container-toolkit, nvidia-cuda-validator, nvidia-dcgm-exporter, nvidia-device-plugin-daemonset, nvidia-driver-daemonset and nvidia-operator-validator running on a GPU enabled nodes. 

```bash 
$ kubectl get all -n gpu-operator
NAME                                                                  READY   STATUS      RESTARTS   AGE
pod/gpu-feature-discovery-5z88x                                       1/1     Running     0          23m
pod/gpu-operator-1720906832-node-feature-discovery-gc-5769c875hsszf   1/1     Running     0          5h59m
pod/gpu-operator-1720906832-node-feature-discovery-master-7999vflt4   1/1     Running     0          5h59m
pod/gpu-operator-1720906832-node-feature-discovery-worker-4lv2d       1/1     Running     0          5h59m
pod/gpu-operator-1720906832-node-feature-discovery-worker-52tfr       1/1     Running     0          27m
pod/gpu-operator-1720906832-node-feature-discovery-worker-jw97f       1/1     Running     0          5h59m
pod/gpu-operator-1720906832-node-feature-discovery-worker-mnhtx       1/1     Running     0          25m
pod/gpu-operator-1720906832-node-feature-discovery-worker-sxs2s       1/1     Running     0          5h59m
pod/gpu-operator-7488b846b-z7vrb                                      1/1     Running     0          5h59m
pod/nvidia-container-toolkit-daemonset-jjgjr                          1/1     Running     0          23m
pod/nvidia-cuda-validator-rk62c                                       0/1     Completed   0          20m
pod/nvidia-dcgm-exporter-cg7n5                                        1/1     Running     0          23m
pod/nvidia-device-plugin-daemonset-9jzkj                              1/1     Running     0          23m
pod/nvidia-driver-daemonset-wt5tn                                     1/1     Running     0          25m
pod/nvidia-operator-validator-gmhjl                                   1/1     Running     0          23m
 
```

### Deploy the Kuberay Operator

Ray is a popular open-source distributed computing framework that is widely used for building and running scalable AI/ML applications. The Kuberay Operator integrates seamlessly with Ray, providing a declarative, Kubernetes-native interface for deploying and managing Ray-powered services.

Install the Kuberay operator, and later in the lab we will create an Inference service using RayService. 

```bash timeout=300 wait=60
$ helm repo add kuberay https://ray-project.github.io/kuberay-helm/
$ helm repo update
# Install the KubeRay operator 1.1.0
$ helm install kuberay-operator kuberay/kuberay-operator --version 1.0.0-rc.0  
```

Check the Ray operator status 

```bash timeout=60 hook=kuberay-operator-check
# Check the KubeRay operator Pod in `default` namespace
$ kubectl get pods
# NAME                                READY   STATUS    RESTARTS   AGE
# kuberay-operator-6fcbb94f64-mbfnr   1/1     Running   0          17s
```

