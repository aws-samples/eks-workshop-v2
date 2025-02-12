---
title: "Deploying the Llama-2-Chat Model on Ray Serve"
sidebar_position: 70
---

With both node pools provisioned, we can now proceed to deploy the Llama2 chatbot infrastructure.

Let's begin by deploying the `ray-service-llama2.yaml` file:

```bash wait=5
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/ray-service-llama2-chatbot
namespace/llama2 created
rayservice.ray.io/llama2 created
```

### Creating the Ray Service Pods for Inference

The `ray-service-llama2.yaml` file defines the Kubernetes configuration for deploying the Ray Serve service for the Llama2 chatbot:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray-service-llama2.yaml
```

This configuration accomplishes the following:

1. Creates a Kubernetes namespace named `llama2` for resource isolation
2. Deploys a RayService named `llama-2-service` that utilizes a Python script to create the Ray Serve component
3. Provisions a Head Pod and Worker Pods to pull Docker images from Amazon Elastic Container Registry (ECR)

After applying the configurations, we'll monitor the progress of the head and worker pods:

```bash wait=5
$ kubectl get pod -n llama2
NAME                                            READY   STATUS    RESTARTS   AGE
pod/llama2-raycluster-fcmtr-head-bf58d          1/1     Running   0          67m
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2   1/1     Running   0          5m30s
```

:::caution
It may take up to 15 minutes for both pods to be ready.
:::

We can wait for the pods to be ready using the following command:

```bash timeout=900
$ kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=llama2 \
--timeout=15m
pod/llama2-raycluster-fcmtr-head-bf58d met
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2 met
```

Once the pods are fully deployed, we'll verify that everything is in place:

```bash
$ kubectl get all -n llama2
NAME                                            READY   STATUS    RESTARTS   AGE
pod/llama2-raycluster-fcmtr-head-bf58d          1/1     Running   0          67m
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2   1/1     Running   0          5m30s

NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
service/llama2             ClusterIP   172.20.118.243   <none>        10001/TCP,8000/TCP,8080/TCP,6379/TCP,8265/TCP   67m
service/llama2-head-svc    ClusterIP   172.20.168.94    <none>        8080/TCP,6379/TCP,8265/TCP,10001/TCP,8000/TCP   57m
service/llama2-serve-svc   ClusterIP   172.20.61.167    <none>        8000/TCP                                        57m

NAME                                        DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY        GPUS   STATUS   AGE
raycluster.ray.io/llama2-raycluster-fcmtr   1                 1                   184    704565270Ki   0      ready    67m

NAME                       SERVICE STATUS   NUM SERVE ENDPOINTS
rayservice.ray.io/llama2   Running          2
```

:::caution
Configuring RayService may take up to 10 minutes.
:::

We can wait for the RayService to be running with this command:

```bash wait=5 timeout=600
$ kubectl wait --for=jsonpath='{.status.serviceStatus}'=Running rayservice/llama2 -n llama2 --timeout=10m
rayservice.ray.io/llama2 condition met
```

With everything properly deployed, we can now proceed to create the web interface for the chatbot.
