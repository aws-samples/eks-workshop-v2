---
title: FSx for Lustre を使用した動的プロビジョニング
sidebar_position: 30
tmdTranslationSourceHash: 028c0dd6ca3cf533e96c296b1760d7bd
---

Kubernetes 用の FSx for Lustre ストレージクラスについて理解したので、UI コンポーネントを変更して FSx for Lustre ボリュームをマウントしましょう。

FSx for Lustre PVC を参照するように UI コンポーネントを更新します:

```kustomization
modules/fundamentals/storage/fsxl/deployment/deployment.yaml
Deployment/ui
```

以下のコマンドでこれらの変更を適用します:

```bash wait=30
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

Deployment の `volumeMounts` を確認しましょう。`fsxlvolume` という名前の新しいボリュームが `/fsxl` にマウントされていることに注目してください:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /fsxl
  name: fsxlvolume
- mountPath: /tmp
  name: tmp-volume
```

PersistentVolume (PV) が静的にプロビジョニングされ、PersistentVolumeClaim (PVC) にバインドされています:

```bash
$ kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS    AGE
fsxl-pv   1200Gi     RWX            Retain           Bound    ui/fsxl-claim    fsx-lustre-sc   5m
```

PersistentVolumeClaim (PVC) の詳細を確認しましょう:

```bash
$ kubectl describe pvc -n ui fsxl-claim
Name:          fsxl-claim
Namespace:     ui
StorageClass:  fsx-lustre-sc
Status:        Bound
Volume:        fsxl-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1200Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       ui-5d4687cf64-phs2w
               ui-5d4687cf64-rc29s
Events:        <none>
```

この時点で、FSx for Lustre ファイルシステムは正常にマウントされていますが、現在は空です:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxl/'
```

[Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) を使用して、FSx for Lustre ボリュームに画像を追加しましょう:

```bash
$ export PVC_NAME="fsxl-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

それでは、UI コンポーネントの Pod の 1 つを通じて `/fsxl` 内の現在のファイルを一覧表示することで、共有ストレージ機能を実証しましょう:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /fsxl/'
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

共有ストレージ機能をさらに実証するために、`placeholder.jpg` という名前の新しい画像を作成し、最初の Pod を通じて FSx for Lustre ボリュームに追加しましょう:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /fsxl/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

次に、2 番目の UI Pod が新しく作成されたファイルにアクセスできることを確認し、FSx for Lustre ストレージの共有性を実証しましょう:

```bash
$ POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /fsxl/'
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

ご覧のように、最初の Pod を通じてファイルを作成したにもかかわらず、2 番目の Pod はすぐにそれにアクセスできます。これは、両方が同じ共有 FSx for Lustre ファイルシステムにアクセスしているためです。

最後に、UI サービスを通じて画像にアクセスできることを確認しましょう:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

ブラウザで URL にアクセスしてください:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/fsx-for-lustre/placeholder.jpg').default}/>
</Browser>

Amazon FSx for Lustre が Amazon EKS 上で実行されるワークロードに高性能な共有並列ストレージを提供する方法を実証することに成功しました。このソリューションにより、複数の Pod が同じストレージボリュームに同時に読み書きできるため、機械学習のトレーニングデータ、HPC ワークロード、メディア処理、および高スループットの並列ファイルシステムアクセスを必要とするその他のユースケースに最適です。

