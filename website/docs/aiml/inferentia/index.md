---
title: "Inference with AWS Inferentia"
sidebar_position: 2
---

[AWS Inferentia](https://aws.amazon.com/machine-learning/inferentia/?nc1=h_ls) is the purpose-built accelerator designed to accelerate deep learning workloads.

Inferentia has processing cores, called Neuron Cores which have high-speed access to models that are stored in on-chip memory.

You can easily use the accelerator on EKS. The Neuron device plugin exposes Neuron cores & devices to Kubernetes as a resource. When your workloads requires neuron cores, the Kubernetes scheduler can assign the Inferentia node to the workloads. You can even provision the node automatically using Karpenter.

This lab provides a tutorial on how to use the Inferentia to accelerate deep learning inference workloads on EKS.

## Compile a model for AWS Neuron

When a model uses AWS Inferentia it should be compiled for it.

This is the code for compiling the model that we will use:

```file
aiml/compiler/trace.py
```

We will run this code using a Pod on EKS. This is the manifest file for the Pod:

```file
aiml/compiler/compiler.yaml
```

Deploy the Pod on the EKS cluster and compile a sample model for Inferentia.

We need [AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/) to compile a model.

The [Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers) provided by AWS has the SDK in it.
The lab uses DLCs to compile a model on EKS and has the image URI as a environment variable.

```bash timeout=300
$ kubectl apply -k /workspace/modules/aiml/compiler/
$ kubectl -n aiml wait --for=condition=Ready --timeout=5m pod/compiler
```

Copy the code for compiling a model on the pod and run it:

```bash timeout=180
$ kubectl -n aiml cp /workspace/modules/aiml/compiler/trace.py compiler:/
$ kubectl -n aiml exec -it compiler -- python /trace.py
```

Upload the model to the S3 bucket that has been created for you.

```bash
$ echo $AIML_NEURON_BUCKET_NAME
$ kubectl -n aiml exec -it compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/
```

## Inference on AWS Inferentia node of Amazon EKS

Now we can use the compiled model to run a inference workload on Inferentia.

### Install Device Plugin for AWS Inferentia

We need to deploy the Neuron device plugin on EKS. It exposes Neuron cores to kubernetes as a resource.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin-rbac.yml
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin.yml
```

When a pod requires the exposed Neuron cores, Kubernetes scheduler can create an Inferentia node to schedule the Pod too.

```file
aiml/inferentia/inference.yaml
```

### Set up a provisioner of Karpenter for launching a node which has the Inferentia chip

The lab uses Karpenter to provison an Inferentia node. Karpenter can detect the pending pod which requires Neuron cores and launch an inf1 instance which has the required Neuron cores.

Karpenter requires a provisioner to provision nodes. This is the Karpenter provisioner that we will create:

```file
aiml/provisioner/provisioner.yaml
```

Apply the provisioner yaml:

```bash
$ kubectl apply -k /workspace/modules/aiml/provisioner/
```

### Create a pod for inference

Now we can deploy a Pod for inference:

```bash
$ kubectl apply -k /workspace/modules/aiml/inferentia/
```

Karpenter detects the pending pod which needs Neuron cores and launches an inf1 instance which has the Inferentia chip. Monitor the instance provisioning with:

```bash test=false
$ kubectl logs -f -n karpenter deploy/karpenter -c controller

2022-10-28T08:24:42.704Z        DEBUG   controller.provisioning.cloudprovider   Created launch template, Karpenter-eks-workshop-cluster-3507260904097783831  {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.125Z        INFO    controller.provisioning.cloudprovider   Launched instance: i-09ddba6280017ae4d, hostname: ip-100-64-10-250.ap-northeast-1.compute.internal, type: inf1.xlarge, zone: ap-northeast-1a, capacityType: spot  {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.136Z        INFO    controller.provisioning Created node with 1 pods requesting {"aws.amazon.com/neuron":"1","cpu":"125m","pods":"6"} from types inf1.xlarge, inf1.2xlarge, inf1.6xlarge, inf1.24xlarge       {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.136Z        INFO    controller.provisioning Waiting for unschedulable pods  {"commit": "37c8653"}
```

The inference pod should be scheduled on the node provisioned by Karpenter. Check if the Pod is in it's ready state:

```bash timeout=360
$ kubectl -n aiml wait --for=condition=Ready --timeout=5m pod/inference
```

### Run a inference

This is the code that we will be using to run inference using a Neuron core on Inferentia:

```file
aiml/inferentia/inference.py
```

Copy the code to the pod and run it:

```bash
$ kubectl -n aiml cp /workspace/modules/aiml/inferentia/inference.py inference:/
$ kubectl -n aiml exec -it inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec -it inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

You can see the result of the inference on the Inferentia.

## Clean up

```bash timeout=180
$ envsubst < <(cat /workspace/modules/aiml/inferentia/inference.yaml) | kubectl -n aiml delete -f -
$ envsubst < <(cat /workspace/modules/aiml/inferentia/compiler.yaml) | kubectl -n aiml delete -f -
$ envsubst < <(cat /workspace/modules/aiml/inferentia/provisioner.yaml) | kubectl delete -f -
$ kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin.yml
$ kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin-rbac.yml
```
