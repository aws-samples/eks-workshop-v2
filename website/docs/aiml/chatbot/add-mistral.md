---
title: "Deploying The Mistral-7B-Instruct-v0.3 Chat Model on Ray Serve"
sidebar_position: 50
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

```bash wait=5 test=false
$ kubectl get pod -n mistral --watch
NAME                                                 READY   STATUS              RESTARTS   AGE
mistral-raycluster-xxhsj-head-l6zwx                  0/2     ContainerCreating   0          3m4s
mistral-raycluster-xxhsj-worker-group-worker-b8wqf   0/1     Init:0/1            0          3m4s
...
mistral-raycluster-xxhsj-head-l6zwx                  1/2     Running             0          3m48s
mistral-raycluster-xxhsj-head-l6zwx                  2/2     Running             0          3m59s
mistral-raycluster-xxhsj-worker-group-worker-b8wqf   0/1     Init:0/1            0          4m25s
mistral-raycluster-xxhsj-worker-group-worker-b8wqf   0/1     PodInitializing     0          4m36s
mistral-raycluster-xxhsj-worker-group-worker-b8wqf   0/1     Running             0          4m37s
mistral-raycluster-xxhsj-worker-group-worker-b8wqf   1/1     Running             0          4m48
```

:::caution
It may take up to 5-8 minutes for both pods to be ready.
:::

We can also use the following command to wait for the pods to get ready:

```bash wait=5 timeout=900
$ for i in {1..2}; do kubectl wait pod --all --for=condition=Ready --namespace=mistral --timeout=10m 2>&1 | grep -v "Error from server (NotFound)" && break || { echo "Attempt $i: Waiting for all pods..."; kubectl get pods -n mistral; sleep 20; }; done

pod/mistral-raycluster-xxhsj-head-l6zwx met
pod/mistral-raycluster-xxhsj-worker-group-worker-b8wqf met
```

Once the pods are fully deployed, we'll verify that everything is in place:

```bash
$ kubectl get all -n mistral
NAME                                                     READY   STATUS    RESTARTS   AGE
pod/mistral-raycluster-xxhsj-head-l6zwx                  2/2     Running   0          5m34s
pod/mistral-raycluster-xxhsj-worker-group-worker-b8wqf   1/1     Running   0          5m34s

NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
service/mistral   ClusterIP   172.20.112.247   <none>        6379/TCP,8265/TCP,10001/TCP,8000/TCP,8080/TCP   2m6s

NAME                                         DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY   GPUS   STATUS   AGE
raycluster.ray.io/mistral-raycluster-xxhsj   1                 1                   6      36Gi     0      ready    5m36s

NAME                        SERVICE STATUS                NUM SERVE ENDPOINTS
rayservice.ray.io/mistral   WaitForServeDeploymentReady   

```
Note that the service status is `WaitForServeDeploymentReady`. This indicates that Ray is still working to get the model deployed.

:::caution
Configuring RayService may take up to 10 minutes.
:::

We can wait for the RayService to be running with this command:

```bash wait=5 timeout=600
$ kubectl wait --for=jsonpath='{.status.serviceStatus}'=Running rayservice/mistral -n mistral --timeout=10m
rayservice.ray.io/mistral condition met
```

With everything properly deployed, we can now proceed to create the web interface for the chatbot.
