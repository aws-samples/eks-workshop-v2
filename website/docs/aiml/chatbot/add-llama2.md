---
title: "Deploying the Llama-2-Chat Model on Ray Serve"
sidebar_position: 30
---

Once both the nodepools have been provisioned, it becomes easier to deploy the Llama2 chatbot infrastructure.

### Creating the Ray Service Pods for Inference

This file defines the Kubernetes configuration for deploying the Ray Serve service for the Llama2 chatbot:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray-service-llama2.yaml
```

The configuration accomplishes the following tasks:

1. Creates a Kubernetes namespace named `Llama2` for isolating resources
2. Deploys a RayService named `Llama-2-service` that leverages the python script to create the Ray Serve component
3. Provisions a Head Pod and Worker Pods to pull Docker Images from Amazon Elastic Container Registry (ECR)

Using the following command, we can deploy `ray-service-llama2.yaml`:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/ray-service-llama2-chatbot
```

After all the configurations are applied, we now want to monitor the progress of the head and worker pods:

```bash
$ kubectl get pod -n llama2
NAME                                            READY   STATUS    RESTARTS   AGE
pod/llama2-raycluster-fcmtr-head-bf58d          1/1     Running   0          67m
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2   1/1     Running   0          5m30s
```

```bash
$ kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=llama2 \
--timeout=10m
pod/llama2-raycluster-fcmtr-head-bf58d met
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2 met
```

:::note
This command can take up to 10 min.
:::

Once the pods are fully deployed, we then want to check if everything is deployed:

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

:::note
Configuring RayService can take up to 10 min.
:::

Once everything has been properly deployed, we can finally create the web interface to run the chatbot.
