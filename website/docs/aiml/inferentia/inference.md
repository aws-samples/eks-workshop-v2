---
title: "Run inference on an AWS Inferentia Node using Amazon EKS"
sidebar_position: 30
---

Now we can use the compiled model to run an inference workload on an AWS Inferentia node.

### Install Device Plugin for AWS Inferentia

In order for our DLC to use the Neuron cores they need to be exposed. The [Neuron device plugin Kubernetes manifest files](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8) expose the Neuron cores to the DLC. These manifest files have been pre-installed into the EKS Cluster.

When a Pod requires the exposed Neuron cores, the Kubernetes scheduler can provision an Inferentia node to schedule the Pod to. This is the Pod that we will schedule. Note that we have a resource requirement of `aws.amazon.com/neuron`.

```file
manifests/modules/aiml/inferentia/inference/inference.yaml
```

### Set up a NodePool of Karpenter for launching a node which has the Inferentia chip

The lab uses Karpenter to provision an Inferentia node. Karpenter can detect the pending pod which requires Neuron cores and launch an inf1 instance which has the required Neuron cores.

Karpenter has been installed in our EKS cluster, and runs as a deployment:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           11m
```

The only setup that we will need to do is to update our EKS IAM mappings to allow Karpenter nodes to join the cluster:

```bash
$ eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME \
    --region $AWS_REGION --arn $KARPENTER_ARN \
    --group system:bootstrappers --group system:nodes \
    --username system:node:{{EC2PrivateDNSName}}
```

Karpenter requires a `NodePool` to provision nodes. This is the Karpenter `NodePool` that we will create:

```file
manifests/modules/aiml/inferentia/nodepool/nodepool.yaml
```

Apply the `NodePool` and `EC2NodeClass` manifest:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/nodepool \
  | envsubst | kubectl apply -f-
```

### Create a pod for inference

Now we can deploy a Pod for inference:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/inference \
  | envsubst | kubectl apply -f-
```

Karpenter detects the pending pod which needs Neuron cores and launches an inf1 instance which has the Inferentia chip. Monitor the instance provisioning with the following command:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter -f | jq
```
```json
{
  "level": "INFO",
  "time": "2023-11-17T21:03:58.827Z",
  "logger": "controller.nodeclaim.lifecycle",
  "message": "launched nodeclaim",
  "commit": "1072d3b",
  "nodeclaim": "aiml-pfwnd",
  "nodepool": "aiml",
  "provider-id": "aws:///us-west-2c/i-0826dc93fb39e3f24",
  "instance-type": "inf1.xlarge",
  "zone": "us-west-2c",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "3920m",
    "ephemeral-storage": "89Gi",
    "memory": "6804Mi",
    "pods": "38",
    "vpc.amazonaws.com/pod-eni": "38"
  }
}
...
```

The inference pod should be scheduled on the node provisioned by Karpenter. Check if the Pod is in it's ready state:

:::note
It can take up to 8 minutes to provision the node, add it to the EKS cluster, and start the pod.
:::

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=8m pod/inference
```

We can use the following command to get more details on the node that was provisioned to schedule our pod onto:

```bash
$ kubectl get node -l karpenter.sh/nodepool=aiml -o jsonpath='{.items[0].status.capacity}' | jq .
```

This output shows the capacity this node has:

```json
{
  "attachable-volumes-aws-ebs": "39",
  "aws.amazon.com/neuron": "1",
  "aws.amazon.com/neuroncore": "4",
  "aws.amazon.com/neurondevice": "1",
  "cpu": "4",
  "ephemeral-storage": "104845292Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "7832960Ki",
  "pods": "38",
  "vpc.amazonaws.com/pod-eni": "38"
}
```

We can see that this node as a `aws.amazon.com/neuron` of 1. Karpenter provisioned this node for us as that's how many neuron the pod requested.

### Run an inference

This is the code that we will be using to run inference using a Neuron core on Inferentia:

```file
manifests/modules/aiml/inferentia/inference/inference.py
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
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/inference/inference.py inference:/
$ kubectl -n aiml exec inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

As output we get the top 5 labels back. We are running the inference on an image of a small kitten using ResNet-50's pre-trained model, so these results are expected. As a possible next step to improve performance we could create our own data set of images and train our own model for our specific use case. This could improve our prediction results.

This concludes this lab on using AWS Inferentia with Amazon EKS.
