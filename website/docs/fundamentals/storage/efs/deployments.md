---
title: Kubernetes deployments
sidebar_position: 10
---

Kubernetes  [deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) describe a desired state in a Deployment, and the Deployment Controller changes the actual state to the desired state at a controlled rate. You can define Deployments to create new ReplicaSets, or to remove existing Deployments and adopt all their resources with new Deployments.

The following are typical use cases for Deployments:

* Create a Deployment to rollout a ReplicaSet. The ReplicaSet creates Pods in the background. Check the status of the rollout to see if it succeeds or not.
* Declare the new state of the Pods by updating the PodTemplateSpec of the Deployment. A new ReplicaSet is created and the Deployment manages moving the Pods from the old ReplicaSet to the new one at a controlled rate. Each new ReplicaSet updates the revision of the Deployment.
* Rollback to an earlier Deployment revision if the current state of the Deployment is not stable. Each rollback updates the revision of the Deployment.
* Scale up the Deployment to facilitate more load.
* Pause the rollout of a Deployment to apply multiple fixes to its PodTemplateSpec and then resume it to start a new rollout.
* Use the status of the Deployment as an indicator that a rollout has stuck.
* Clean up older ReplicaSets that you don't need anymore.

On our ecommerce application, we have a deployment already created as part of our Assets microservice. The Assets microservice utilizes a Nginx webserver running on EKS. Webservers are a great example for the use of deployments because they require **scale horizontally** and Declare the new state of the Pods. 

Assets component is an nginx container which serves static images for products, these product images are added as part of the docker image build. unfortunatly with this setup evrytime the team want to update the product images they have to recreate the docker image. In this exrecise By utilizing [EFS File system](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) and Kuberneties [presistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) we will help the team update old product images and add new product images with out the need to rebuild the containers images.

We can start by describe the deployment to ensure it is exist, by running the following command:

```bash
$ kubectl describe deployment -n assets
```

As you can see in the output of the previous command the [`volumeMounts`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) section of our `deployment` defines what is the `monuntPath` that will be mounted into a specific volume.

It's currently just utilizing a [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Run the following command to confirm and check under the `name: tmp-volume` volume:

```bash
$ kubectl get deployment -n assets -o json | jq '.items[].spec.template.spec.volumes'

[
  {
    "emptyDir": {
      "medium": "Memory"
    },
    "name": "tmp-volume"
  }
]
```

The nginx conatiner has the product images copied to it as part of the docker build under the folder /usr/share/nginx/html/assets/, we can check by running the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```

Now let us try to put a new product image in the directory using the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "touch /usr/share/nginx/html/assets/newproduct.png" 

```
Now confirm the new product image has been created in the folder, using the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```
Now let's remove the current `assets` pod. This will force the deployment controller to automatically re-create a new assets pod:

```bash
$ kubectl delete --all pods --namespace=assetss

pod "assets-ddb8f87dc-ww4jn" deleted

$ kubectl wait --for=condition=available --timeout=120s deployment/assets -n assets
```
Now let us check if the image we created for the new product "newproduct.png" is still exist:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```

As you see the newly Created image newproduct.png is not exist now , as it is not been copied while the creation of the Docker image. In order to help the team solve this issue we need a presistent volume conatin the images. that can be shared across multiple pods if the team want to scale horizintally.

Now that we have a better understading of EKS Storage and Kubernetes objects. On the next page, we will talk more about EFS CSI Driver and how we can Utilize it ro create a persistent storage on Kuberneties using Dynamic Provisioning on Elastic file system.

