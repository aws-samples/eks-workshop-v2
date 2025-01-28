---
title: "Deploying The Mistral-7B-Instruct-v0.3 Chat Model on Ray Serve"
sidebar_position: 60
---

With all the node pools provisioned, we can now proceed to deploy Mistral-7B-Instruct-v0.3 chatbot infrastructure.

Let's begin by deploying the `ray-service-mistral.yaml` file:

```bash wait=5
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/ray-service-neuron-mistral-chatbot
namespace/mistral created
rayservice.ray.io/mistral created
```

### Creating the Ray Service Pods for Inference

The `ray-service-mistral.yaml` file defines the Kubernetes configuration for deploying the Ray Serve service for the mistral7bv0.3 AI chatbot:

```file
manifests/modules/aiml/chatbot/ray-service-neuron-mistral-chatbot/ray_service_mistral.yaml
```

This configuration accomplishes the following:

1. Creates a Kubernetes namespace named `mistral` for resource isolation
2. Deploys a RayService named `rayservice.ray.io/mistral` that utilizes a Python script to create the Ray Serve component
3. Provisions a Head Pod and Worker Pods to pull Docker images from Amazon Elastic Container Registry (ECR)

After applying the configurations, we'll monitor the progress of the head and worker pods:

```bash wait=5
$ kubectl get pod -n mistral
NAME                                                    READY   STATUS    RESTARTS   AGE
pod/mistral-raycluster-ltvjb-head-7rd7d                  0/2     Pending   0          4s
pod/mistral-raycluster-ltvjb-worker-worker-group-nff7x   0/1     Pending   0          4s
```

:::caution
It may take up to 15 minutes for both pods to be ready.
:::

We can wait for the pods to be ready using the following command:

```bash timeout=900
$ kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=mistral \
--timeout=15m
pod/mistral-raycluster-ltvjb-head-7rd7d met
pod/mistral-raycluster-ltvjb-worker-worker-group-nff7x met
```

Once the pods are fully deployed, we'll verify that everything is in place:

```bash
$ kubectl get all -n mistral
NAME                                                     READY   STATUS    RESTARTS   AGE
pod/mistral-raycluster-ltvjb-head-7rd7d                  2/2     Running   0          7m
pod/mistral-raycluster-ltvjb-worker-worker-group-nff7x   1/1     Running   0          7m

NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                       AGE
service/mistral             NodePort       172.20.74.49    <none>           6379:32625/TCP,8265:30941/TCP,10001:32430/TCP,8000:31393/TCP,8080:31361/TCP   94m
service/mistral-head-svc    NodePort       172.20.121.46   <none>           8000:30481/TCP,8080:32609/TCP,6379:31066/TCP,8265:31006/TCP,10001:30220/TCP   92m
service/mistral-serve-svc   NodePort       172.20.241.50   <none>           8000:32351/TCP                                                                92m

NAME                                         DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY   GPUS   STATUS   AGE
raycluster.ray.io/mistral-raycluster-ltvjb   1                 1                   2      36Gi     0      ready    94m

NAME                        SERVICE STATUS   NUM SERVE ENDPOINTS
rayservice.ray.io/mistral   Running          2
```

:::caution
Configuring RayService may take up to 10 minutes.
:::

We can wait for the RayService to be running with this command:

```bash wait=5 timeout=600
$ kubectl wait --for=jsonpath='{.status.serviceStatus}'=Running rayservice/mistral -n mistral --timeout=10m
rayservice.ray.io/mistral condition met
```

With everything properly deployed, we can now proceed to create the web interface for the chatbot.
