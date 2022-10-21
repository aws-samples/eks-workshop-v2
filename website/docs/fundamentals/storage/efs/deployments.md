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

On our ecommerce application, we have a deployment already deployed part of our Assets microservice. The Assets microservice utilizes a Nginx webserver running on EKS. Webservers are a great example for the use of deployments because they require **scale horizontally** and Declare the new state of the Pods by updating the PodTemplateSpec of the Deploymentwhen we attach to it the EFS volume. We can analyze our Nginx container on the Asset service, by running the following command:

```bash
$ kubectl describe deployment -n assets
```

As you can see the [`volumeMounts`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) section of our `deployment` defines what is the `monuntPath` that will be mounted into a specific volume:

```blank title="manifests/ssets/deployment.yaml " 
          volumeMounts:
            - mountPath: /tmp
              name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
```

In our case the `volumeMounts` called `tmp-volume` has a `mountPath` of `/tmp` directory, Kubernetes will map to a `volume` with the same name, which is the `emptyDir` with name of `data` that you see on the last two lines of the snippet above. 

Assets component is an nginx container which serves static images for products, these images are added as part of the container image build. unfortunatly with this setup evry time the team want to update the photos of teh product they have to recreate the image.It's currently just utilizing a [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Run the following command to confirm and check under the `name: tmp-volume` volume:

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

The nginx conatiner has the images of the product copied to it as part of the build under the folder /usr/share/nginx/html/assets/ we can check by running the below command:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```
Now let us try to put another image in the directory using the below command:


```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "touch /usr/share/nginx/html/assets/newproduct.png" 

```

let us check that the new image has been created in the folder, using the below command:


```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```

Now let's remove the current `assets` pod. This will force the deployment controller to automatically re-create a new assets pod:

```bash
$ kubectl delete pod assets-ddb8f87dc-ww4jn -n assets

pod "assets-ddb8f87dc-ww4jn" deleted
```

Now let us check if the image we created for the new product "newproduct.png" if it is still exist:


```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /usr/share/nginx/html/assets/" 

```

As you see the newly Crated image we put new product it not exist now , as it is not been copied while the creation of the Docker image. In order to help the team solve that we need a file system that can be shared across multiple containers. that will be presistent volume conatin the images .

Now that we have a better understading of EKS Storage and Kubernetes objects. On the next page, we will take more about EFS and how we can Utilize it as a persistent storage on Kuberneties using Dynamic Provisioning.

