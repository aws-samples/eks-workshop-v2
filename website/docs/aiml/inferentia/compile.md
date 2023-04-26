---
title: "Compile a Pre-Trained Model for AWS Inferentia"
sidebar_position: 20
---

When you want a model uses AWS Inferentia it needs be compiled for use with AWS Inferentia using the AWS Neuron SDK.

This is the code for compiling the model that we will use:

```file
aiml/compiler/trace.py
```

This code loads the pre-trained ResNet-50 model and sets it to evaluation mode. Note that we are not adding any additional training data to the model. We then save the model using the AWS Neuron SDK.

We will run this code in a Pod on EKS. This is the manifest file for running the Pod:

```file
aiml/compiler/compiler.yaml
```

We will deploy the Pod on the EKS cluster and compile a sample model for use with AWS Inferentia. Compiling a model for AWS Inferentia requires the [AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/). This SDK is included with the [Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers) that are provided by AWS.

This lab uses DLC to compile the model on EKS. Create the Pod by running the following commands and wait for the Pod to meet the Ready condition.

```bash timeout=300
$ kubectl apply -k /workspace/modules/aiml/compiler/
$ kubectl -n aiml wait --for=condition=Ready --timeout=5m pod/compiler
```

Next, copy the code for compiling a model on to the pod and run it:

```bash timeout=180
$ kubectl -n aiml cp /workspace/modules/aiml/compiler/trace.py compiler:/
$ kubectl -n aiml exec -it compiler -- python /trace.py
```

Finally, upload the model to the S3 bucket that has been created for you. This will ensure we can use the model later in the lab.

```bash
$ kubectl -n aiml exec -it compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/
```
