---
title: "Compile a pre-trained model for AWS Inferentia"
sidebar_position: 20
---

When you want a model to leverage AWS Inferentia it needs be compiled for use with AWS Inferentia using the AWS Neuron SDK.

This is the code for compiling the model that we will use:

```file
manifests/modules/aiml/inferentia/compiler/trace.py
```

This code loads the pre-trained ResNet-50 model and sets it to evaluation mode. Note that we are not adding any additional training data to the model. We then save the model using the AWS Neuron SDK.

We will run this code in a Pod on EKS. This is the manifest file for running the Pod:

```file
manifests/modules/aiml/inferentia/compiler/compiler.yaml
```

We will deploy the Pod on the EKS cluster and compile a sample model for use with AWS Inferentia. Compiling a model for AWS Inferentia requires the [AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/). This SDK is included with the [Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers) that are provided by AWS.

This lab uses DLC to compile the model on EKS. Create the Pod by running the following commands and wait for the Pod to meet the Ready condition.

```bash timeout=600
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/compiler \
  | envsubst | kubectl apply -f-
$ kubectl -n aiml wait --for=condition=Ready --timeout=10m pod/compiler
```

:::note
This command can take up to 10 min.
:::

Next, copy the code for compiling a model on to the pod and run it:

```bash timeout=240
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/compiler/trace.py compiler:/
$ kubectl -n aiml exec compiler -- python /trace.py

....
Compiler status PASS
INFO:Neuron:Number of arithmetic operators (post-compilation) before = 175, compiled = 175, percent compiled = 100.0%
INFO:Neuron:The neuron partitioner created 1 sub-graphs
INFO:Neuron:Neuron successfully compiled 1 sub-graphs, Total fused subgraphs = 1, Percent of model sub-graphs successfully compiled = 100.0%
INFO:Neuron:Compiled these operators (and operator counts) to Neuron:
INFO:Neuron: => aten::_convolution: 53
INFO:Neuron: => aten::adaptive_avg_pool2d: 1
INFO:Neuron: => aten::add_: 16
INFO:Neuron: => aten::batch_norm: 53
INFO:Neuron: => aten::flatten: 1
INFO:Neuron: => aten::linear: 1
INFO:Neuron: => aten::max_pool2d: 1
INFO:Neuron: => aten::relu_: 49

```

Finally, upload the model to the S3 bucket that has been created for you. This will ensure we can use the model later in the lab.

```bash
$ kubectl -n aiml exec compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/

upload: ./resnet50_neuron.pt to s3://eksworkshop-inference20230511204343601500000001/resnet50_neuron.pt
```
