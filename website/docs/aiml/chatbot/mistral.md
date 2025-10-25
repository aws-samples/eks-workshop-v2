---
title: "Serving the model"
sidebar_position: 40
---

[vLLM](https://github.com/vllm-project/vllm) is an open-source inference and serving engine specifically designed to optimize the performance of large language models (LLMs) through efficient memory management. As a popular inference solution in the ML community, vLLM offers several key advantages:

- **Efficient Memory Management**: Uses PagedAttention technology to optimize GPU/accelerator memory usage
- **High Throughput**: Enables concurrent processing of multiple requests
- **AWS Neuron Support**: Native integration with AWS Inferentia and Trainium accelerators
- **OpenAI-compatible API**: Provides a drop-in replacement for OpenAI's API, simplifying integration

For AWS Neuron specifically, vLLM provides:

- Native support for Neuron SDK and runtime
- Optimized memory management for Inferentia/Trainium architectures
- Continuous model loading for efficient scaling
- Integration with AWS Neuron profiling tools

For this lab, we will use the [Mistral-7B-v0.3 model](https://mistral.ai/news/announcing-mistral-7b) compiled with the `neuronx-distributed-inference` framework. This model provides a good balance between capabilities and resource requirements, making it suitable for deployment on our Trainium-powered EKS cluster.

To deploy the model, we'll use a standard Kubernetes Deployment that will use a vLLM-based container image to load the model and weights:

::yaml{file="manifests/modules/aiml/chatbot/vllm.yaml"}

Let's create the necessary resources:

```bash
$ kubectl create namespace vllm
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/chatbot/vllm.yaml
```

We can check the resources it created:

```bash
$ kubectl get deployment -n vllm
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mistral   0/1     1            0           33s
$ kubectl get service -n vllm
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mistral   ClusterIP   172.16.149.89   <none>        8080/TCP   33m
```

The model initialization process takes several minutes to complete. The vLLM Pod will go through the following stages:

1. Remain in a Pending state until Karpenter provisions the Trainium instance
2. Use an init container to download the model from Hugging Face to a host file system path
3. Download the vLLM container image (approximately 10GB)
4. Start the vLLM service
5. Load the model from the file system
6. Begin serving the model via an HTTP endpoint on port 8080

You can either monitor the status of the Pod as it progresses through these stages or proceed to the next section while the model loads.

If you choose to wait, you can watch the Pod transition to the Init state (press Ctrl + C to exit):

```bash test=false
$ kubectl get pod -n vllm --watch
NAME                       READY   STATUS    RESTARTS   AGE
mistral-6889d675c5-2l6x2   0/1     Pending   0          21s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          30s
mistral-6889d675c5-2l6x2   0/1     Pending   0          38s
mistral-6889d675c5-2l6x2   0/1     Pending   0          50s
mistral-6889d675c5-2l6x2   0/1     Init:0/1   0          50s
# Exit once the Pod reaches the Init state
```

You can check the logs for the init container that's downloading the model (press Ctrl + C to exit):

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c model-download -f
[...]
Downloading 'weights/tp0_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/dAuF3Bw92r-GdZ-yzT84Iweq-RQ=.6794a3d7f2b1d071399a899a42bcd5652e83ebdd140f02f562d90b292ae750aa.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp0_sharded_checkpoint.safetensors
Downloading 'weights/tp1_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/eEdQSCIfRYQ2putRDwZhjh7Te8E=.14c5bd3b07c4f4b752a65ee99fe9c79ae0110c7e61df0d83ef4993c1ee63a749.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp1_sharded_checkpoint.safetensors

Model download is complete.
# Exit once the logs reach this point
```

Once the init container completes, you can monitor the vLLM container logs as it starts (press Ctrl + C to exit):

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c vllm -f
[...]
INFO 09-30 04:43:37 [launcher.py:36] Route: /v2/rerank, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /invocations, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /metrics, Methods: GET
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     10.42.114.242:38674 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.114.242:50134 - "GET /health HTTP/1.1" 200 OK
# Exit once the logs reach this point
```

After completing these steps or deciding to move on while the model initializes, you can proceed to the next task.
