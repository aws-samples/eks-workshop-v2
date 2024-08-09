---
title: "Install Karpenter, Nvidia GPU and Ray Operators"
sidebar_position: 20
description: "Install Karpenter, Nvidia GPU and Ray Operators"
---


# Install Karpenter

The first thing we'll do is install Karpenter in our cluster. Various pre-requisites were created during the lab preparation stage, including:

1. An IAM role for Karpenter to call AWS APIs
2. An IAM role and instance profile for the EC2 instances that Karpenter creates
3. An EKS cluster access entry for the node IAM role so the nodes can join the EKS cluster
4. An SQS queue for Karpenter to receive Spot interruption, instance re-balance and other events

You can find the full installation documentation for Karpenter [here](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/).

All that we have left to do is install Karpenter:

```bash timeout=1800 wait=30
$ helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace "karpenter" --create-namespace \
  --set "settings.clusterName=${EKS_CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${KARPENTER_SQS_QUEUE}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --set replicas=1 \
  --wait 
```

Karpenter will be running as a deployment in the `karpenter` namespace:

```bash hook=check-karpenter-deployment-status timeout=150
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           105s
```

For this lab, we will create two `NodePool` and `EC2NodeClass` with the following command, one to scale g5.2xlarge GPU EC2 instance and the second one to scale non-GPU instance-type.

```bash timeout=180 hook=karpenter-nodepool-ec2nodeclass-status 
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/karpenter \
  | envsubst | kubectl apply -f-
$ kubectl get nodepool,ec2nodeclass
NAME                                      NODECLASS
nodepool.karpenter.sh/g5-gpu-karpenter    g5-gpu-karpenter
nodepool.karpenter.sh/x86-cpu-karpenter   x86-cpu-karpenter

NAME                                               AGE
ec2nodeclass.karpenter.k8s.aws/g5-gpu-karpenter    32m
ec2nodeclass.karpenter.k8s.aws/x86-cpu-karpenter   32ms
```

Throughout the workshop you can inspect the Karpenter logs with the following command to understand its behavior:

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter 
```


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

