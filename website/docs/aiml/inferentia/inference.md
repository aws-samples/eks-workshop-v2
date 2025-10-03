---
title: "Run inference on AWS Inferentia"
sidebar_position: 40
---

Now we can use the compiled model to run an inference workload on an AWS Inferentia node.

### Create a pod for inference

Check the image that we'll run the inference on:

```bash
$ echo $AIML_DL_INF_IMAGE
```

This is a different image than we used for training and has been optimized for inference.

Now we can deploy a Pod for inference. This is the manifest file for running the inference Pod:

::yaml{file="manifests/modules/aiml/inferentia/inference/inference.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. For the Inference we've set the `nodeSelector` section to specify a inf2 instance type.
2. In the `resources` `limits` section again we specify that we need a neuron core to run this Pod to expose the API.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/inference \
  | envsubst | kubectl apply -f-
```

Again Karpenter detects the pending Pod which this time needs a inf2 instance with needs Neuron cores. So Karpenter launches an inf2 instance which has the Inferentia chip. You can again monitor the instance provisioning with the following command:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
...
{
  "level": "INFO",
  "time": "2024-09-19T18:53:34.266Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-v64vm"
  },
  "namespace": "",
  "name": "aiml-v64vm",
  "reconcileID": "7b5488c5-957a-4051-a657-44fb456ad99b",
  "provider-id": "aws:///us-west-2b/i-0078339b1c925584d",
  "instance-type": "inf2.xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "3920m",
    "ephemeral-storage": "89Gi",
    "memory": "14162Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "18"
  }
}
...
```

The inference Pod should be scheduled on the node provisioned by Karpenter. Check if the Pod is in its ready state:

:::note
It can take up to 12 minutes to provision the node, add it to the EKS cluster, and start the pod.
:::

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=12m pod/inference
```

We can use the following command to get more details on the node that was provisioned to schedule our pod onto:

```bash
$ kubectl get node -l karpenter.sh/nodepool=aiml -o jsonpath='{.items[0].status.capacity}' | jq .
```

This output shows the capacity this node has:

```json
{
  "aws.amazon.com/neuron": "1",
  "aws.amazon.com/neuroncore": "2",
  "aws.amazon.com/neurondevice": "1",
  "cpu": "4",
  "ephemeral-storage": "104845292Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "16009632Ki",
  "pods": "58",
  "vpc.amazonaws.com/pod-eni": "18"
}
```

We can see that this node has an `aws.amazon.com/neuron` of 1. Karpenter provisioned this node for us as that's how many Neuron cores the Pod requested.

### Run inference

This is the code that we will be using to run inference using a Neuron core on Inferentia:

```file
manifests/modules/aiml/inferentia/inference/inference.py
```

This Python code does the following tasks:

1. Downloads and stores an image of a small kitten.
2. Fetches the labels for classifying the image.
3. Imports this image and normalizes it into a tensor.
4. Loads our previously created model.
5. Runs the prediction on our small kitten image.
6. Gets the top 5 results from the prediction and prints these to the command-line.

We'll copy this code to the Pod, download our previously uploaded model, and run the following commands:

```bash
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/inference/inference.py inference:/
$ kubectl -n aiml exec inference -- pip install --upgrade boto3==1.40.16 botocore==1.40.16
$ kubectl -n aiml exec inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

As output we get the top 5 labels back. We are running the inference on an image of a small kitten using ResNet-50's pre-trained model, so these results are expected. As a possible next step to improve performance we could create our own data set of images and train our own model for our specific use case. This could improve our prediction results.

This concludes this lab on using AWS Inferentia with Amazon EKS.
