---
title: Dynamic provisioning using EFS
sidebar_position: 30
---

Now that we understand [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) and [Kuberneties storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/), let's create a [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and change the Nginx container on the assets deployment to mount the Volume created.

First inspect the `efspvclaim.yaml` file to see the parameters in the file and the claim of the specific storage size of 5GB from the Storage class `efs-sc` we created in the earlier step:

```file
fundamentals/storage/efs/deployment/efspvclaim.yaml
```

We'll also modify the assets service is two ways:

* Remove the EmptyDir volume with `tmp-volume` named.
* Add the Volume Claim and Volume Mounts to the specs of our containers.

```kustomization
fundamentals/storage/efs/deployment/deployment.yaml
Deployment/assets
```

We can apply the changes by running the following command:

```bash hook=efs-deployment hookTimeout=90
$ kubectl apply -k /workspace/modules/fundamentals/storage/efs/deployment
[...]
$ kubectl rollout status --timeout=130s deployment/assets -n assets
```

Now look at the `volumeMounts` in the deployment, notice that we have our new `Volume` named `efsvolume` mounted on`volumeMounts` named `/efsvolumedir`:

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
```

A `PersistentVolume` (PV) has been created automatically for the `PersistentVolumeClaim` (PVC) we had created in the previous step:

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    assets/efs-claim                      efs-sc                  2m33s
```

Also describe the `PersistentVolumeClaim` (PVC) created:

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

Now create a new JPG photo `newproduct.png` under the newly Mounted file system `/efsvolumedir`, by running the below command"

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "touch /efsvolumedir/newproduct.png"
```

Confirm that the new image file `newproduct.png` has been created:

```bash
$ kubectl exec --stdin deployment/assets -n assets -- bash -c "ls /efsvolumedir"
newproduct.png
```

Now let's remove the current `assets` pod. This will force the deployment controller to automatically re-create a new `assets` pod:

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




