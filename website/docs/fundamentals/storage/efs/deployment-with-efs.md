---
title: Dynamic provisioning using EFS and Kuberneties deployment 
sidebar_position: 30
---

Now that we understand [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) and [Kuberneties storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/), let's create a [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the Nginx container on the assets deployment to mount the Volume created.

first inspect the efspvclaim.yaml file to see the parameters in the file and the claim of the specific storage size of 5GB from the Storage class "efs-sc" we created in the earlier step:

```bash
$ cat modules/fundamentals/storage/efs/efspvclaim.yaml 

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: assets
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi%          
```
Now create the PVC. Run the below command:

```bash
$ kubectl apply -f modules/fundamentals/storage/efs/efspvclaim.yaml
persistentvolumeclaim/efs-claim created

$ kubectl wait --for=condition=available --timeout=60s persistentvolumeclaim/efs-claim -n assets
```

Now show the PV has been created automatically for the PVC we had created in the previous step:

```bash
$ kubectl get pv

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    assets/efs-claim                      efs-sc                  2m33s
```
Also describe the PVC created. Run the below Command:

```bash
$ kubectl describe pvc -n assets

Name:          efs-claim
Namespace:     assets
StorageClass:  efs-sc
Status:        Bound
Volume:        pvc-342a674d-b426-4214-b8b6-7847975ae121
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: efs.csi.aws.com
               volume.kubernetes.io/storage-provisioner: efs.csi.aws.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                 Age                From                                                                               Message
  ----    ------                 ----               ----                                                                               -------
  Normal  ExternalProvisioning   22m (x2 over 22m)  persistentvolume-controller                                                        waiting for a volume to be created, either by external provisioner "efs.csi.aws.com" or manually created by system administrator
  Normal  Provisioning           22m                efs.csi.aws.com_ip-10-42-11-246.ec2.internal_1b9196ea-2586-49a6-87dd-5ce1d78c4c0d  External provisioner is provisioning volume for claim "assets/efs-claim"
  Normal  ProvisioningSucceeded  22m                efs.csi.aws.com_ip-10-42-11-246.ec2.internal_1b9196ea-2586-49a6-87dd-5ce1d78c4c0d  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121

```
Now Utilizing Kustomiza we will do two things:

* Remove the EmptyDir volume with `tmp-volume` named.
* Add the Volume Claim and Volume Mounts to the specs of our containers.

```kustomization
fundamentals/storage/efs/deployment.yaml
Deployment/assets
```

We can apply the Kustomize changes to the deployment by Run the following command:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/storage/efs

namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets configured

$ kubectl wait --for=condition=available --timeout=120s deployment/assets -n assets
```
Now get the volumeMounts in the deployment and Notice that we have our new Volume "efsvolume" mounted /efsvolumedir . Run the Follwing command

```bash
$ kubectl get deployment -n assets -o json | jq '.items[].spec.template.spec.containers[].volumeMounts' 

[
  {
    "mountPath": "/efsvolumedir",
    "name": "efsvolume"
  },
  {
    "mountPath": "/tmp",
    "name": "tmp-volume"
  }
]

$ kubectl wait --for=condition=available --timeout=120s deployment/assets -n assets
```

Now check that the POD is ready, run the below command:
```bash
$ kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=assets -n assets --timeout=60s

pod/assets-6487bdc64-9qd6s condition met

```
Now create a new JPG photo under the newly Mounted file system /efsvolumedir: run the following command"

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "touch /efsvolumedir/newproduct.png"
```

Confirm it has been created:
```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /efsvolumedir"

newproduct.png
```

Now let's remove the current `assets` pod. This will force the deployment controller to automatically re-create a new assets pod:

```bash
$ kubectl delete --all pods --namespace=assets

pod "assets-6897999c5-vx46q" deleted

$ kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=assets -n assets --timeout=60s
```

Now check if the file new JPG file has been created in the step above still exist on the new created container:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /efsvolumedir"

newproduct.png
```
Now as you can see even though we have a new POD created after we deleted the old pod we still can see the file on the Directory . This is the main functionality of Persistent Volumes (PVs). Amazon EFS is storing the data and keeping our data safe and available .




