---
title: "Run Inference on an AWS Inferentia Node using Amazon EKS"
sidebar_position: 30
---

Now we can use the compiled model to run an inference workload on an AWS Inferentia node.

### Install Device Plugin for AWS Inferentia

In order for our DLC to use the Neuron cores they need to be exposed. The [Neuron device plugin Kubernetes manifest files](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8) expose the Neuron cores to the DLC. These manifest files have been pre-installed into the EKS Cluster.

When a Pod requires the exposed Neuron cores, the Kubernetes scheduler can provision an Inferentia node to schedule the Pod to. This is the Pod that we will schedule. Note that we have a resource requirement of `aws.amazon.com/neuron`.

```file
aiml/inference/inference.yaml
```

### Set up a provisioner of Karpenter for launching a node which has the Inferentia chip

The lab uses Karpenter to provision an Inferentia node. Karpenter can detect the pending pod which requires Neuron cores and launch an inf1 instance which has the required Neuron cores.

:::tip
You can learn more about Karpenter in the [Karpenter module](../../autoscaling/compute/karpenter/index.md) that's provided in this workshop.
:::

Karpenter requires a provisioner to provision nodes. This is the Karpenter provisioner that we will create:

```file
aiml/provisioner/provisioner.yaml
```

Apply the provisioner manifest:

```bash
$ kubectl apply -k /workspace/modules/aiml/provisioner/
```

### Create a pod for inference

Now we can deploy a Pod for inference:

```bash
$ kubectl apply -k /workspace/modules/aiml/inference/
```

Karpenter detects the pending pod which needs Neuron cores and launches an inf1 instance which has the Inferentia chip. Monitor the instance provisioning with the following command:

```bash test=false
$ kubectl logs -f -n karpenter deploy/karpenter -c controller

2022-10-28T08:24:42.704Z        DEBUG   controller.provisioning.cloudprovider   Created launch template, Karpenter-eks-workshop-cluster-3507260904097783831  {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.125Z        INFO    controller.provisioning.cloudprovider   Launched instance: i-09ddba6280017ae4d, hostname: ip-100-64-10-250.ap-northeast-1.compute.internal, type: inf1.xlarge, zone: ap-northeast-1a, capacityType: spot  {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.136Z        INFO    controller.provisioning Created node with 1 pods requesting {"aws.amazon.com/neuron":"1","cpu":"125m","pods":"6"} from types inf1.xlarge, inf1.2xlarge, inf1.6xlarge, inf1.24xlarge       {"commit": "37c8653", "provisioner": "default"}
2022-10-28T08:24:45.136Z        INFO    controller.provisioning Waiting for unschedulable pods  {"commit": "37c8653"}
```

The inference pod should be scheduled on the node provisioned by Karpenter. Check if the Pod is in it's ready state:

:::note
It can take up to 7 minutes to provision the node, add it to the EKS cluster, and start the pod.
:::

```bash timeout=360
$ kubectl -n aiml wait --for=condition=Ready --timeout=8m pod/inference
```

### Run an inference

This is the code that we will be using to run inference using a Neuron core on Inferentia:

```file
aiml/inference/inference.py
```

This Python code does the following tasks:

1. It downloads and stores an image of a small kitten.
2. It fetches the labels for classifying the image.
3. It then imports this image and normalizes it into a tensor.
4. It loads our previously created model.
5. It runs the prediction on our small kitten image.
6. It gets the top 5 results from the prediction and prints these to the command-line.

We copy this code to the Pod, download our previously uploaded model, and run the code:

```bash
$ kubectl -n aiml cp /workspace/modules/aiml/inference/inference.py inference:/
$ kubectl -n aiml exec -it inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec -it inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

As output we get the top 5 labels back. We are running the inference on an image of a small kitten using ResNet-50's pre-trained model, so these results are expected. As a possible next step to improve performance we could create our own data set of images and train our own model for our specific use case. This could improve our prediction results.

This concludes this lab on using AWS Inferentia with Amazon EKS.

## Clean up

Run the following commands to clean up the resources from this lab:

```bash
$ kubectl delete namespace aiml
$ kubectl delete awsnodetemplate.karpenter.k8s.aws/aiml
$ kubectl delete provisioner/aiml
```
