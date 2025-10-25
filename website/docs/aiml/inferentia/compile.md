---
title: "Compile a pre-trained model"
sidebar_position: 30
---

When you want a model to leverage AWS Inferentia it needs be compiled for use with AWS Inferentia using the AWS Neuron SDK.

This is the code for compiling the model to use Inferentia that we will use:

```file
manifests/modules/aiml/inferentia/compiler/trace.py
```

This code loads the pre-trained ResNet-50 model and sets it to evaluation mode. Note that we are not adding any additional training data to the model. We then save the model using the AWS Neuron SDK.

We will deploy the Pod on the EKS cluster and compile a sample model for use with AWS Inferentia. Compiling a model for AWS Inferentia requires the [AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/). This SDK is included with the [Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers) that are provided by AWS.

### Install the Device Plugin

In order for our DLC to use the Neuron cores, they need to be exposed. The [Neuron device plugin Kubernetes manifest files](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8) expose the Neuron cores to the DLC. These manifest files have been pre-installed into the EKS Cluster.

When a Pod requires the exposed Neuron cores, the Kubernetes scheduler can provision an Inferentia or Trainium node to schedule the Pod to.

Check the image that we'll run:

```bash
$ echo $AIML_DL_TRN_IMAGE
```

### Create a Pod for Training

We will run this code in a Pod on EKS. This is the manifest file for running the Pod:

::yaml{file="manifests/modules/aiml/inferentia/compiler/compiler.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. In the `nodeSelector` section we specify the instance type we want to run this pod on. In this case a trn1 instance.
2. In the `resources` `limits` section we specify that we need a neuron core to run this Pod. This will tell the Neuron Device Plugin to expose the neuron API to the Pod.

Create the Pod by running the following command:

```bash timeout=900
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/compiler \
  | envsubst | kubectl apply -f-
```

Karpenter detects the pending Pod which needs a trn1 instance and Neuron cores and launches an trn1 instance which meets the requirements. Monitor the instance provisioning with the following command:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
{
  "level": "INFO",
  "time": "2024-09-19T18:44:08.919Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-hp9wm"
  },
  "namespace": "",
  "name": "aiml-hp9wm",
  "reconcileID": "b38f0b3c-f146-4544-8ddc-ca73574c97f0",
  "provider-id": "aws:///us-west-2b/i-06bc9a7cb6f92887c",
  "instance-type": "trn1.2xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "7910m",
    "ephemeral-storage": "89Gi",
    "memory": "29317Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "17"
  }
}
```

The Pod should be scheduled on the node provisioned by Karpenter. Check if the Pod is in its ready state:

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=10m pod/compiler
```

:::warning
This command can take up to 10 minutes.
:::

Next, copy the code for compiling a model on to the Pod and run it:

```bash timeout=240
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/compiler/trace.py compiler:/
$ kubectl -n aiml exec compiler -- python /trace.py

....
Downloading: "https://download.pytorch.org/models/resnet50-0676ba61.pth" to /root/.cache/torch/hub/checkpoints/resnet50-0676ba61.pth
100%|-------| 97.8M/97.8M [00:00<00:00, 165MB/s]
.
Compiler status PASS
```

Finally, upload the model to the S3 bucket that has been created for you. This will ensure we can use the model later in the lab.

```bash
$ kubectl -n aiml exec compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/

upload: ./resnet50_neuron.pt to s3://eksworkshop-inference20230511204343601500000001/resnet50_neuron.pt
```
