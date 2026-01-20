---
title: Dynamic provisioning using EFS
sidebar_position: 30
kiteTranslationSourceHash: a8a98c88b4517b1cb20411160dceed1b
---

EFS用のKubernetesストレージクラスについて理解したので、[永続ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を作成し、UIコンポーネントを変更してこのボリュームをマウントしましょう。

まず、`efspvclaim.yaml`ファイルを確認しましょう：

::yaml{file="manifests/modules/fundamentals/storage/efs/deployment/efspvclaim.yaml" paths="kind,spec.storageClassName,spec.resources.requests.storage"}

1. 定義されているリソースはPersistentVolumeClaimです
2. これは先ほど作成した`efs-sc`ストレージクラスを参照しています
3. 5GBのストレージを要求しています

次に、UIコンポーネントを更新してEFS PVCを参照するようにします：

```kustomization
modules/fundamentals/storage/efs/deployment/deployment.yaml
Deployment/ui
```

以下のコマンドで変更を適用します：

```bash hook=efs-deployment
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/efs/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolumeclaim/efs-claim created
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

デプロイメントの`volumeMounts`を調べてみましょう。`efsvolume`という名前の新しいボリュームが`/efs`にマウントされていることがわかります：

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /efs
  name: efsvolume
- mountPath: /tmp
  name: tmp-volume
```

PersistentVolumeClaimを満たすためにPersistentVolume（PV）が自動的に作成されました：

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS   REASON   AGE
pvc-342a674d-b426-4214-b8b6-7847975ae121   5Gi        RWX            Delete           Bound    ui/efs-claim                      efs-sc                  2m33s
```

PersistentVolumeClaim（PVC）の詳細を確認しましょう：

```bash
$ kubectl describe pvc -n ui
Name:          efs-claim
Namespace:     ui
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
  Type    Reason                 Age   From                                                                                      Message
  ----    ------                 ----  ----                                                                                      -------
  Normal  ExternalProvisioning   34s   persistentvolume-controller                                                               waiting for a volume to be created, either by external provisioner "efs.csi.aws.com" or manually created by system administrator
  Normal  Provisioning           34s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  External provisioner is provisioning volume for claim "ui/efs-claim"
  Normal  ProvisioningSucceeded  33s   efs.csi.aws.com_efs-csi-controller-6b4ff45b65-fzqjb_7efe91cc-099a-45c7-8419-6f4b0a4f9e01  Successfully provisioned volume pvc-342a674d-b426-4214-b8b6-7847975ae121
```

この時点で、EFSファイルシステムは正常にマウントされていますが、現在は空です：

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /efs/'
```

[Kubernetesジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を使用して、EFSボリュームに画像を投入しましょう：

```bash
$ export PVC_NAME="efs-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

UIコンポーネントのPodの一つを通して、`/efs`内の現在のファイルをリストして、共有ストレージ機能を実証しましょう：

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /efs/'
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

共有ストレージ機能をさらに実証するために、最初のPodを通じて`placeholder.jpg`という新しい画像を作成し、EFSボリュームに追加しましょう：

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /efs/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

次に、2番目のUIポッドがこの新しく作成されたファイルにアクセスできることを確認し、EFSストレージの共有特性を実証します：

```bash hook=sample-images
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /efs/'
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

ご覧の通り、最初のPodを通じてファイルを作成したにもかかわらず、2番目のPodは同じ共有EFSファイルシステムにアクセスしているため、すぐにアクセスできます。

最後に、UIサービスを通じて画像にアクセスできることを確認しましょう：

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

ブラウザでURLにアクセスしてください：

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('./assets/placeholder.jpg').default}/>
</Browser>

Amazon EFSがAmazon EKS上で実行されるワークロードに永続的な共有ストレージを提供する方法を正常に実証しました。このソリューションにより、複数のPodが同時に同じストレージボリュームから読み取りや書き込みを行うことができ、共有コンテンツホスティングや分散ファイルシステムアクセスを必要とする他のユースケースに最適です。
