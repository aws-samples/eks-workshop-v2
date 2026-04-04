---
title: "ImagePullBackOff - ECR Private Image"
sidebar_position: 71
tmdTranslationSourceHash: 'b5a2b92141292b8a19d14b5994f180d1'
---

이 섹션에서는 ECR 프라이빗 이미지에 대한 Pod ImagePullBackOff 오류를 해결하는 방법을 배웁니다. 이제 배포가 생성되었는지 확인하여 시나리오 문제 해결을 시작할 수 있습니다.

```bash
$ kubectl get deploy ui-private -n default
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
ui-private   0/1     1            0           4m25s
```

:::info
동일한 출력을 얻었다면 문제 해결을 시작할 준비가 된 것입니다.
:::

이 문제 해결 섹션에서 여러분의 과제는 배포 ui-private가 0/1 준비 상태에 있는 원인을 찾아 이를 수정하여 배포가 하나의 Pod를 준비하고 실행할 수 있도록 하는 것입니다.

## 문제 해결 시작하기

### 단계 1: Pod 상태 확인

먼저 Pod의 상태를 확인해야 합니다.

```bash
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS             RESTARTS   AGE
ui-private-7655bf59b9-jprrj   0/1     ImagePullBackOff   0          4m42s
```

### 단계 2: Pod 상세 정보 확인

Pod 상태가 ImagePullBackOff로 표시되는 것을 볼 수 있습니다. 이벤트를 확인하기 위해 Pod를 상세히 살펴보겠습니다.

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

Pod의 이벤트에서 403 Forbidden을 원인으로 하는 'Failed to pull image' 경고를 볼 수 있습니다. 이는 kubelet이 배포에 사용된 이미지를 가져오려고 할 때 액세스가 거부되었음을 나타냅니다. 배포에 사용된 이미지의 URI를 가져오겠습니다.

```bash
$ kubectl get deploy ui-private -o jsonpath='{.spec.template.spec.containers[*].image}'
"1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
```

### 단계 3: 이미지 참조 확인

이미지 URI에서 이미지는 EKS 클러스터가 있는 계정에서 참조되고 있습니다. 해당 이미지가 존재하는지 ECR 리포지토리를 확인해 보겠습니다.

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

배포에 있는 이미지 경로 즉, account_id.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1은 유효한 registryId 즉, account-number, 유효한 repositoryName 즉, "retail-sample-app-ui" 그리고 유효한 imageTag 즉, "1.2.1"을 가지고 있습니다. 이는 이미지 경로가 올바르며 잘못된 참조가 아님을 확인시켜 줍니다.

:::info
또는 ECR 콘솔에서도 확인할 수 있습니다. 아래 버튼을 클릭하여 ECR 콘솔을 엽니다. 그런 다음 retail-sample-app-ui 리포지토리와 이미지 태그 1.2.1을 클릭합니다.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/ecr/private-registry/repositories?region=us-west-2"
  service="ecr"
  label="ECR 콘솔 탭 열기"
/>
:::

### 단계 4: kubelet 권한 확인

이미지 URI가 올바른 것을 확인했으므로, kubelet의 권한을 확인하고 ECR에서 이미지를 가져오는 데 필요한 권한이 있는지 확인하겠습니다.

클러스터의 관리형 노드 그룹에서 워커 노드에 연결된 IAM 역할을 가져오고 해당 역할에 연결된 IAM 정책을 나열합니다.

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

AWS 관리형 정책 "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"가 워커 노드 역할에 연결되어 있으며, 이 정책은 ECR 프라이빗 리포지토리에서 이미지를 가져오기에 충분한 권한을 제공해야 합니다.

### 단계 5: ECR 리포지토리 권한 확인

ECR 리포지토리에 대한 권한은 Identity 및 Resource 수준 모두에서 관리할 수 있습니다. Identity 수준 권한은 IAM에서 제공되고 리소스 수준 권한은 리포지토리 수준에서 제공됩니다. Identity 기반 권한이 정상임을 확인했으므로 ECR 리포지토리의 정책을 확인하겠습니다.

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

ECR 리포지토리 정책의 Effect가 Deny이고 Principal이 EKS 관리형 노드 역할입니다. 이는 kubelet이 이 리포지토리에서 이미지를 가져오는 것을 제한하고 있습니다. Effect를 allow로 변경하고 kubelet이 이미지를 가져올 수 있는지 확인하겠습니다.

:::note
ECR 리포지토리 권한을 수정하기 위해 아래 json 파일을 사용합니다.

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

### 단계 6: 배포 재시작 및 Pod 상태 확인

이제 배포를 재시작하고 Pod가 실행 중인지 확인합니다.

```bash timeout=180 hook=fix-2 hookTimeout=600 wait=20
$ kubectl rollout restart deploy ui-private
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS    RESTARTS   AGE
ui-private-7655bf59b9-s9pvb   1/1     Running   0          65m
```

## 마무리

프라이빗 이미지의 ImagePullBackOff가 있는 Pod에 대한 일반적인 문제 해결 워크플로는 다음과 같습니다:

- "not found", "access denied" 또는 "timeout"과 같은 문제의 원인에 대한 단서를 얻기 위해 Pod 이벤트를 확인합니다.
- "not found"인 경우 프라이빗 ECR 리포지토리에서 참조된 경로에 이미지가 존재하는지 확인합니다.
- "access denied"인 경우 워커 노드 역할과 ECR 리포지토리 정책의 권한을 확인합니다.
- ECR에 대한 timeout의 경우 워커 노드가 ECR 엔드포인트에 도달하도록 구성되어 있는지 확인합니다.

## 추가 리소스

- [ECR on EKS](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html)
- [ECR Repository Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html)
- [EKS Networking](https://docs.aws.amazon.com/eks/latest/userguide/eks-networking.html)
