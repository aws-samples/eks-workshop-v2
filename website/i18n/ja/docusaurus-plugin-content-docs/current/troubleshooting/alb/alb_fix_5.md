---
title: "IAMポリシーの問題"
sidebar_position: 31
tmdTranslationSourceHash: 5f51c26fd2fef5b5078614ccdff8f7ee
---

このセクションでは、AWS Load Balancer ControllerがApplication Load Balancerを作成・管理するために必要なIAMアクセス許可がないという問題に対処します。IAMポリシー設定の問題を特定して修正する手順を説明します。

### ステップ1：Service AccountのRoleを特定する

まず、Load Balancer Controllerが使用しているservice accountを調べます。ControllerはAWS APIを呼び出すためにIAM Roles for Service Accounts (IRSA)を使用しています：

```bash
$ kubectl get serviceaccounts -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o yaml
```

出力例：

::yaml{file="manifests/modules/troubleshooting/alb/files/iam_issue_service_account_role.yaml" paths="items.0.metadata.annotations"}

1. `eks.amazonaws.com/role-arn`：このタグは、正しいアクセス許可が必要なIAM roleを参照しています。

### ステップ2：Controllerのログを確認する

Load Balancer Controllerのログを調べて、アクセス許可の問題を理解しましょう：

```bash wait=25  expectError=true
$ kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

次のようなエラーが表示されるかもしれません：

```text
{"level":"error","ts":"2024-06-11T14:24:24Z","msg":"Reconciler error","controller":"ingress","object":{"name":"ui","namespace":"ui"},"namespace":"ui","name":"ui","reconcileID":"49d27bbb-96e5-43b4-b115-b7a07e757148","error":"AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action\n\tstatus code: 403, request id: a24a1620-3a75-46b7-b3c3-9c80fada159e"}
```

このエラーは、IAM roleに`elasticloadbalancing:CreateLoadBalancer`アクセス許可がないことを示しています。

### ステップ3：IAMポリシーを修正する

この問題を解決するには、正しいアクセス許可でIAM roleを更新する必要があります。このワークショップでは、[AWS Load Balancer Controllerのインストールガイド](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)に基づいて、必要なIAMポリシーのアクセス許可を持つ正しいポリシーをあらかじめ作成しています。

次の手順で修正します：

#### 3.1. 正しいポリシーをアタッチする

```bash
$ aws iam attach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX}
```

#### 3.2. 誤ったポリシーを削除する

```bash
$ aws iam detach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE}
```

#### 3.3. 新しいサブネット設定を反映させるためにLoad Balancer Controllerを再起動する

```bash
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
deployment.apps/aws-load-balancer-controller restarted
$ kubectl -n kube-system wait --for=condition=available deployment/aws-load-balancer-controller
```

### ステップ4：修正を確認する

IngressがALBで正しく設定されているかどうかを確認します：

```bash timeout=600 hook=fix-5 hookTimeout=600
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-ui-5ddc3ba496-1208241872.us-west-2.elb.amazonaws.com
```

:::tip
**ロードバランサーの作成には数分かかることがあります**。次の方法で進行状況を確認できます：

1. CloudTrailで成功した`CreateLoadBalancer` API呼び出しを確認する
2. Controllerログで作成成功のメッセージを監視する
3. IngressリソースでALB DNS名が表示されるのを待つ

:::

AWS Load Balancer Controllerに必要な完全なアクセス許可セットは、[公式ドキュメント](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/#setup-iam-manually)で確認できます。
