---
title: "Model Inference"
sidebar_position: 50
---


In this section we will create an inference service for Dogbooth using [Kuberay operator](https://ray-project.github.io/kuberay/components/operator/), [RayService](https://ray-project.github.io/kuberay/guidance/rayservice/) CRD

### Deploy the Nginx Ingress Controller to expose the Inference service

In this module, we will deploy the nginx ingress controller which can help create the Network Load balancer for the Inference service

```bash timeout=300 wait=60
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update

```

We will use the values.yaml file for deploying the ingress controller.

```file
manifests/modules/aiml/deploy-monitor-genai-model/rayservice/ingress-nginx-values.yaml
```


```bash timeout=300 wait=60
$ helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.admissionWebhooks.enabled=false -f ~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/rayservice/ingress-nginx-values.yaml
```



### Deploy the Ray Service

We have provided a ray-service.yaml to create the inference service, in this example we have used an existing model "askulkarni2/dogbooth" foro this inference, alternatively you can also use the model id uploaded to your hugging face from the previous training step.

```text
apiVersion: ray.io/v1alpha1
kind: RayService
metadata:
  name: dogbooth
  namespace: dogbooth
spec:
  serviceUnhealthySecondThreshold: 600
  deploymentUnhealthySecondThreshold: 600
  serveConfig:
    importPath: dogbooth:entrypoint
    runtimeEnv: |
      env_vars: {"MODEL_ID": "askulkarni2/dogbooth"}

```


Deploy the Ray services and the Ingress service to access it

```bash timeout=1800 wait=60
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/rayservice/rayservice.yaml
```

The above deployment will take roughly 10 mins to complete. Let's verify the deployments:

```bash timeout=300 wait=60
$ kubectl  get all -n dogbooth
NAME                                                     READY   STATUS    RESTARTS   AGE
pod/dogbooth-raycluster-9j8kw-head-87l8r                 1/1     Running   0          30h
pod/dogbooth-raycluster-9j8kw-worker-small-group-9x4n8   1/1     Running   0          30h

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                       AGE
service/dogbooth-head-svc                    ClusterIP   10.100.202.221   <none>        10001/TCP,8265/TCP,52365/TCP,6379/TCP,8080/TCP,8000/TCP                                       30h
service/dogbooth-raycluster-9j8kw-head-svc   NodePort    10.100.104.57    <none>        10001:31035/TCP,8265:30043/TCP,52365:32583/TCP,6379:32712/TCP,8080:32015/TCP,8000:31494/TCP   30h
service/dogbooth-serve-svc                   ClusterIP   10.100.125.143   <none>        8000/TCP                                                                           
```


Let's run the below command to get the NLB Endpoint 

```bash timeout=300 wait=60
$ kubectl get ingress -n dogbooth
NAME       CLASS   HOSTS   ADDRESS                                                                   PORTS   AGE
dogbooth   alb     *       k8s-dogbooth-dogbooth-2757fb0219-1791700772.us-west-2.elb.amazonaws.com   80      7h14m

$ kubectl get ingress -n dogbooth -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
k8s-dogbooth-dogbooth-2757fb0219-1791700772.us-west-2.elb.amazonaws.com

```


Let's now run a sample inference: Copy the NLB Endpoint in the browser and run a prompt as below

http://NLBENDPOINT/dogbooth/serve/imagine?prompt=a photo of [v]happy pup

This should generate an image like below :

![Happy pup](./assets/happy-pup.jpeg)
