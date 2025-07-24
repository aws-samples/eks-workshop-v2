---
title: Dynamic provisioning using FSx for NetApp ONTAP
sidebar_position: 30
---

Now that we understand the FSx for NetApp ONTAP storage class for Kubernetes, let's create a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and modify the UI component to mount this volume.


First, let's examine the `fsxnpvclaim.yaml` file:

::yaml{file="manifests/modules/fundamentals/storage/fsxn/deployment/fsxnpvclaim.yaml" paths="kind,spec.storageClassName,spec.resources.requests.storage"}

1. The resource being defined is a PersistentVolumeClaim
2. This refers to the 'fsxn-sc-nfs' storage class we created earlier
3. We are requesting 5GB of storage 


Now we'll update the UI component to reference the FSx for NetApp ONTAP PVC:

```kustomization
modules/fundamentals/storage/fsxn/deployment/deployment.yaml
Deployment/ui
```

Apply these changes with the following command:

```bash wait=30
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolumeclaim/fsxn-nfs-claim created
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

Let's examine the `volumeMounts` in the deployment. Notice that our new volume named `fsxnvolume` is mounted at `/fsxn`:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /fsxn
  name: fsxnvolume
- mountPath: /tmp
  name: tmp-volume
```

A PersistentVolume (PV) has been automatically created to fulfill our PersistentVolumeClaim (PVC):

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    ui/fsxn-claim                      fsxn-sc-nfs                  2m33s
```

Let's examine the details of our PersistentVolumeClaim (PVC):

```bash
$ kubectl describe pvc -n ui
Name:          fsxn-claim
Namespace:     ui
StorageClass:  fsxn-sc-nfs
Status:        Bound
Volume:        pvc-342a674d-b426-4214-b8b6-7847975ae121
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: csi.trident.netapp.io
               volume.kubernetes.io/storage-provisioner: csi.trident.netapp.io
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                 Age   From                                                                                      Message
  ----    ------                 ----  ----                                                                                      -------
  Normal  ExternalProvisioning   34s   persistentvolume-controller                                                               waiting for a volume to be created, either by external provisioner "csi.trident.netapp.io" or manually created by system administrator
  Normal  Provisioning           34s   csi.trident.netapp.io_trident-csi-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  External provisioner is provisioning volume for claim "ui/fsxn-claim"
  Normal  ProvisioningSucceeded  33s   csi.trident.netapp.io_trident-csi-6b9cdcddf6-kwx7p_35a063fc-5d91-4ba1-9bce-4d71de597b14  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

At this point, the FSx for NetApp ONTAP file system is successfully mounted but currently empty:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxn/'
```

Let's use a [Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) to populate the FSx for NetApp ONTAP volume with images:

```bash
$ export PVC_NAME="fsxn-nfs-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

Now let's demonstrate the shared storage functionality by listing the current files in `/fsxn` through one of the UI component Pods:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxn/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
```

To further demonstrate the shared storage capabilities, let's create a new image called `placeholder.jpg` and add it to the FSx for NetApp ONTAP volume through the first Pod:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /fsxn/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

Now we'll verify that the second UI Pod can access this newly created file, demonstrating the shared nature of our FSx for NetApp ONTAP storage:

```bash
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /fsxn/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
placeholder.jpg      <----------------
```

As you can see, even though we created the file through the first Pod, the second Pod has immediate access to it because they're both accessing the same shared FSx for NetApp ONTAP file system.

Finally, let's confirm that the image is accessible through the UI service:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

Visit the URL in your browser:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('./assets/placeholder.jpg').default}/>
</Browser>

We've successfully demonstrated how Amazon FSx for NetApp ONTAP provides persistent shared storage for workloads running on Amazon EKS. This solution allows multiple pods to read from and write to the same storage volume simultaneously, making it ideal for shared content hosting and other use cases requiring distributed file system access with enterprise-grade features and performance.
