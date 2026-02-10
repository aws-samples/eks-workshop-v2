---
title: "ImagePullBackOff - ECRプライベートイメージ"
sidebar_position: 71
tmdTranslationSourceHash: b5a2b92141292b8a19d14b5994f180d1
---

このセクションでは、ECRプライベートイメージに対するポッドのImagePullBackOffエラーをトラブルシューティングする方法を学びます。まず、デプロイメントが作成されたことを確認して、トラブルシューティングのシナリオを開始できるようにしましょう。

```bash
$ kubectl get deploy ui-private -n default
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
ui-private   0/1     1            0           4m25s
```

:::info
同じ出力が表示される場合は、トラブルシューティングを開始する準備ができています。
:::

このトラブルシューティングセクションでのあなたの課題は、デプロイメント ui-private が 0/1 準備完了状態になっている原因を突き止め、デプロイメントに1つのポッドが準備完了して実行されるように修正することです。

## トラブルシューティングを始めましょう

### ステップ1：ポッドの状態を確認する

まず、ポッドの状態を確認する必要があります。

```bash
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS             RESTARTS   AGE
ui-private-7655bf59b9-jprrj   0/1     ImagePullBackOff   0          4m42s
```

### ステップ2：ポッドを詳細に調べる

ポッドの状態がImagePullBackOffとして表示されています。ポッドを詳細に調べて、イベントを確認しましょう。

```bash expectError=true
$ POD=`kubectl get pods -l app=app-private -o jsonpath='{.items[*].metadata.name}'`
$ kubectl describe pod $POD | awk '/Events:/,/^$/'
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  5m15s                  default-scheduler  Successfully assigned default/ui-private-7655bf59b9-jprrj to ip-10-42-33-232.us-west-2.compute.internal
  Normal   Pulling    3m53s (x4 over 5m15s)  kubelet            Pulling image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
  Warning  Failed     3m53s (x4 over 5m14s)  kubelet            Failed to pull image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": failed to pull and unpack image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": failed to resolve reference "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": unexpected status from HEAD request to https:/"1234567890.dkr.ecr.us-west-2.amazonaws.com/v2/retail-sample-app-ui/manifests/1.2.1: 403 Forbidden
  Warning  Failed     3m53s (x4 over 5m14s)  kubelet            Error: ErrImagePull
  Warning  Failed     3m27s (x6 over 5m14s)  kubelet            Error: ImagePullBackOff
  Normal   BackOff    4s (x21 over 5m14s)    kubelet            Back-off pulling image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
```

ポッドのイベントから、「Failed to pull image」警告が表示され、原因として403 Forbiddenとあります。これは、kubeletがデプロイメントで使用されているイメージをプルしようとした際にアクセス拒否に直面したことを示しています。デプロイメントで使用されているイメージのURIを取得しましょう。

```bash
$ kubectl get deploy ui-private -o jsonpath='{.spec.template.spec.containers[*].image}'
"1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
```

### ステップ3：イメージ参照をチェックする

イメージURIから、イメージはEKSクラスタがあるアカウントから参照されています。ECRリポジトリをチェックして、そのようなイメージが存在するかどうかを確認しましょう。

```bash
$ aws ecr describe-images --repository-name retail-sample-app-ui --image-ids imageTag=1.2.1
{
    "imageDetails": [
        {
            "registryId": "1234567890",
            "repositoryName": "retail-sample-app-ui",
            "imageDigest": "sha256:b338785abbf5a5d7e0f6ebeb8b8fc66e2ef08c05b2b48e5dfe89d03710eec2c1",
            "imageTags": [
                "1.2.1"
            ],
            "imageSizeInBytes": 268443135,
            "imagePushedAt": "2024-10-11T14:03:01.207000+00:00",
            "imageManifestMediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "artifactMediaType": "application/vnd.docker.container.image.v1+json"
        }
    ]
}
```

デプロイメントにあるイメージパス、つまりaccount_id.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1は、有効なregistryId（アカウント番号）、有効なrepositoryName（「retail-sample-app-ui」）、有効なimageTag（「1.2.1」）を持っています。これにより、イメージのパスが正しく、間違った参照ではないことが確認できます。

:::info
または、ECRコンソールからも確認できます。以下のボタンをクリックしてECRコンソールを開きます。次に、retail-sample-app-uiリポジトリをクリックし、イメージタグ1.2.1をクリックします。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/ecr/private-registry/repositories?region=us-west-2"
  service="ecr"
  label="Open ECR Console Tab"
/>
:::

### ステップ4：kubeletの権限を確認する

イメージURIが正しいことを確認したので、kubeletの権限を確認し、ECRからイメージをプルするために必要な権限が存在するかどうかを確認しましょう。

クラスタのマネージドノードグループに接続されているIAMロールを取得し、そのロールに接続されているIAMポリシーをリストアップします。

```bash
$ ROLE_NAME=`aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name default --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2`
$ aws iam list-attached-role-policies --role-name $ROLE_NAME
{
    "AttachedPolicies": [
        {
            "PolicyName": "AmazonSSMManagedInstanceCore",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        {
            "PolicyName": "AmazonEC2ContainerRegistryReadOnly",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        },
        {
            "PolicyName": "AmazonEKSWorkerNodePolicy",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        },
        {
            "PolicyName": "AmazonSSMPatchAssociation",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
        }
    ]
}
```

AWS管理ポリシー「arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly」がワーカーノードロールに接続されており、このポリシーはECRプライベートリポジトリからイメージをプルするのに十分な権限を提供するはずです。

### ステップ5：ECRリポジトリの権限をチェックする

ECRリポジトリへの権限は、アイデンティティレベルとリソースレベルの両方で管理できます。アイデンティティレベルの権限はIAMで提供され、リソースレベルの権限はリポジトリレベルで提供されます。アイデンティティベースの権限が良好であることを確認したので、ECRリポジトリのポリシーを確認しましょう。

```bash
$ aws ecr get-repository-policy --repository-name retail-sample-app-ui --query policyText --output text | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/EksNodeGroupRole"
      },
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:SetRepositoryPolicy",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:GetRepositoryPolicy",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DeleteRepository",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:BatchDeleteImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

ECRリポジトリポリシーのEffectは「Deny」で、PrincipalはEKSマネージドノードロールです。これにより、kubeletがこのリポジトリのイメージをプルすることが制限されています。Effectを「Allow」に変更して、kubeletがイメージをプルできるかどうかを確認しましょう。

:::note
ECRリポジトリの権限を変更するために、以下のjsonファイルを使用します。

```json {6}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/EksNodeGroupRole"
      },
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:SetRepositoryPolicy",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:GetRepositoryPolicy",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DeleteRepository",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:BatchDeleteImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

:::

```bash
$ export ROLE_ARN=`aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name default --query 'nodegroup.nodeRole'`
$ echo '{"Version":"2012-10-17","Statement":[{"Sid":"new policy","Effect":"Allow","Principal":{"AWS":'${ROLE_ARN}'},"Action":["ecr:BatchCheckLayerAvailability","ecr:BatchDeleteImage","ecr:BatchGetImage","ecr:CompleteLayerUpload","ecr:DeleteRepository","ecr:DeleteRepositoryPolicy","ecr:DescribeRepositories","ecr:GetDownloadUrlForLayer","ecr:GetRepositoryPolicy","ecr:InitiateLayerUpload","ecr:ListImages","ecr:PutImage","ecr:SetRepositoryPolicy","ecr:UploadLayerPart"]}]}' > ~/ecr-policy.json
$ aws ecr set-repository-policy --repository-name retail-sample-app-ui --policy-text file://~/ecr-policy.json
```

### ステップ6：デプロイメントを再起動してポッドの状態を確認する

ここで、デプロイメントを再起動して、ポッドが実行されているかどうかを確認します。

```bash timeout=180 hook=fix-2 hookTimeout=600 wait=20
$ kubectl rollout restart deploy ui-private
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS    RESTARTS   AGE
ui-private-7655bf59b9-s9pvb   1/1     Running   0          65m
```

## まとめ

プライベートイメージに対するImagePullBackOffのあるポッドの一般的なトラブルシューティングワークフローには、以下が含まれます：

- 「not found」、「access denied」、「timeout」などの問題の原因に関するヒントについて、ポッドイベントを確認します。
- 「not found」の場合は、イメージがプライベートECRリポジトリで参照されているパスに存在することを確認します。
- 「access denied」の場合は、ワーカーノードロールとECRリポジトリポリシーの権限を確認します。
- ECRでのタイムアウトについては、ワーカーノードがECRエンドポイントに到達するように構成されていることを確認します。

## 追加リソース

- [ECR on EKS](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html)
- [ECR Repository Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html)
- [EKS Networking](https://docs.aws.amazon.com/eks/latest/userguide/eks-networking.html)
