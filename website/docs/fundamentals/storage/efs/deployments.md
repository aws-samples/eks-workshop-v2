---
title: Persistent network storage
sidebar_position: 10
---

On our ecommerce application, we have a deployment already created as part of our assets microservice. The assets microservice utilizes a nginx webserver running on EKS. Webservers are a great example for the use of deployments because they require **scale horizontally** and **declare the new state** of the Pods. 

Assets component is a nginx container which serves static images for products, these product images are added as part of the container image build. unfortunately with this setup everytime the team wants to update the product images they have to recreate the container image. In this exrercise By utilizing [EFS File system](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) and Kubernetes [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) we will help the team update old product images and add new product images without the need to rebuild the containers images.

We can start by describe the deployment to ensure it is exist, by running the following command:

```bash
$ kubectl describe deployment -n assets
Name:                   assets
Namespace:              assets
[...]
  Containers:
   assets:
    Image:      watchn/watchn-assets:build.1666365372
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  128Mi
    Requests:
      cpu:     128m
      memory:  128Mi
    Liveness:  http-get http://:8080/health.html delay=30s timeout=1s period=3s #success=1 #failure=3
    Environment Variables from:
      assets      ConfigMap  Optional: false
    Environment:  <none>
    Mounts:
      /tmp from tmp-volume (rw)
  Volumes:
   tmp-volume:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
[...]
```

As you can see in the output of the previous command the [`volumeMounts`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) section of our `deployment` defines what is the `mountPath` that will be mounted into a specific volume.

It's currently just utilizing a [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Run the following command to confirm and check under the `name: tmp-volume` volume:

```bash
$ kubectl get deployment -n assets -o jsonpath='{.items[].spec.template.spec.volumes}' | jq
[
  {
    "emptyDir": {
      "medium": "Memory"
    },
    "name": "tmp-volume"
  }
]
```

The nginx container has the product images copied to it as part of the docker build under the folder `/usr/share/nginx/html/assets`, we can check by running the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

chrono_classic.jpg
gentleman.jpg
pocket_watch.jpg
smart_1.jpg
smart_2.jpg
wood_watch.jpg
```

Now let us try to put a new product image named `newproduct.png` in the directory `/usr/share/nginx/html/assets` using the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "touch /usr/share/nginx/html/assets/newproduct.png" 

```
Now confirm the new product image `newproduct.png` has been created in the folder `/usr/share/nginx/html/assets`, using the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls usr/share/nginx/html/assets/newproduct.png"  

/usr/share/nginx/html/assets/newproduct.png
```
Now let's remove the current `assets` pod. This will force the deployment controller to automatically re-create a new `assets` pod:

```bash wait=60
$ kubectl delete --all pods --namespace=assets
pod "assets-ddb8f87dc-ww4jn" deleted
$ kubectl wait --for=condition=available --timeout=120s deployment/assets -n assets
```
Now let us check if the image we created for the new product `newproduct.png` is still exist:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 
```

As you see the newly created image `newproduct.png` is not exist now , as it is not been copied while the creation of the container image. In order to help the team solve this issue we need a `PersistentVolume` contain the images. That can be shared across multiple pods if the team want to scale horizontally.

Now that we have a better understanding of EKS Storage and kubernetes objects. On the next page, we will talk more about EFS CSI Driver and how we can utilize it to create a persistent storage on kubernetes using dynamic provisioning on Elastic File System.
