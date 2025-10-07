---
title: "Privileged PSS profile"
sidebar_position: 61
kiteTranslationSourceHash: 260e8ab341719985f9ce028e79bddcd1
---

最初に、最も許容的で既知の権限昇格を許可するPrivilegedプロファイルを調査することからPSSの調査を始めましょう。

Kubernetesバージョン1.23以降では、デフォルトで、すべてのPSAモード（enforce、audit、warnなど）がクラスターレベルでPrivileged PSSプロファイルに対して有効化されています。つまり、デフォルトでは、PSAはすべての名前空間でPrivileged PSSプロファイル（つまり、制限がない状態）を持つDeploymentやPodを許可します。これらのデフォルト設定はクラスターへの影響を最小限に抑え、アプリケーションへの悪影響を減らします。後ほど見るように、名前空間のラベルを使用して、より制限的な設定を選択できます。

デフォルトでは、`pss`名前空間にPSAラベルが明示的に追加されていないことを確認できます：

```bash
$ kubectl describe ns pss
Name:         pss
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=pss
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

ご覧のとおり、`pss`名前空間にはPSAラベルが付いていません。

また、`pss`名前空間で現在実行されているDeploymentとPodも確認しましょう。

```bash
$ kubectl -n pss get deployment
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
pss    1/1     1            1           5m24s
$ kubectl -n pss get pod
NAME                     READY   STATUS    RESTARTS   AGE
pss-ddb8f87dc-8z6l9    1/1     Running   0          5m24s
```

pss PodのYAMLを表示すると、現在のセキュリティ設定が確認できます：

```bash
$ kubectl -n pss get deployment pss -o yaml | yq '.spec.template.spec'
containers:
  - image: public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.1
    imagePullPolicy: IfNotPresent
    name: pss
    ports:
      - containerPort: 80
        protocol: TCP
    resources: {}
    securityContext:
      readOnlyRootFilesystem: false
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
dnsPolicy: ClusterFirst
restartPolicy: Always
schedulerName: default-scheduler
securityContext: {}
terminationGracePeriodSeconds: 30
```

上記のPodセキュリティ設定では、Pod レベルでの`securityContext`がnilです。コンテナレベルでは、`securityContext`は`readOnlyRootFilesystem`がfalseに設定されています。deploymentとPodがすでに実行されていることは、PSA（デフォルトでPrivileged PSSプロファイル用に設定されている）が上記のPodセキュリティ設定を許可していることを示しています。

しかし、このPSAはどのようなセキュリティ管理を許可しているのでしょうか？それを確認するために、上記のPodセキュリティ設定にさらに権限を追加して、PSAが`pss`名前空間でそれを許可するかどうかをチェックしましょう。具体的には、Podに`privileged`フラグと`runAsUser:0`フラグを追加します。これはモニタリングエージェントやサービスメッシュサイドカーなどのワークロードでよく必要とされるホストリソースへのアクセスが可能になり、また`root`ユーザーとして実行することも許可されます：

```kustomization
modules/security/pss-psa/privileged-workload/deployment.yaml
Deployment/pss
```

Kustomizeを実行して上記の変更を適用し、PSAが上記のセキュリティ権限を持つPodを許可するかどうかを確認します。

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/privileged-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

`pss`名前空間で上記のセキュリティ権限を持つDeploymentとPodが再作成されたかどうか確認しましょう

```bash
$ kubectl -n pss get pod
NAME                      READY   STATUS    RESTARTS   AGE
pss-64c49f848b-gmrtt      1/1     Running   0          9s

$ kubectl -n pss exec $(kubectl -n pss get pods -o name) -- whoami
root
```

これは、Privileged PSSプロファイル用に有効になっているデフォルトのPSAモードが許容的であり、必要に応じてPodが昇格されたセキュリティ権限を要求することを許可していることを示しています。

上記のセキュリティ権限はPrivileged PSSプロファイルで許可されている管理の包括的なリストではありません。各PSSプロファイルで許可/禁止されている詳細なセキュリティ管理については、[ドキュメント](https://kubernetes.io/docs/concepts/security/pod-security-standards/)を参照してください。
