---
title: "EKS Pod Identity 사용하기"
sidebar_position: 34
hide_table_of_contents: true
tmdTranslationSourceHash: 'cd634a113e19b4c86057e0ea79176751'
---

EKS 클러스터에서 EKS Pod Identity를 사용하려면 `EKS Pod Identity Agent` 애드온이 EKS 클러스터에 설치되어 있어야 합니다. 다음 명령어를 사용하여 설치해 보겠습니다:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
{
    "addon": {
        "addonName": "eks-pod-identity-agent",
        "clusterName": "eks-workshop",
        "status": "CREATING",
        "addonVersion": "v1.1.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-west-2:1234567890:addon/eks-workshop/eks-pod-identity-agent/9ec6cfbd-8c9f-7ff4-fd26-640dda75bcea",
        "createdAt": "2024-01-12T22:41:01.414000+00:00",
        "modifiedAt": "2024-01-12T22:41:01.434000+00:00",
        "tags": {}
    }
}

$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
```

이제 새 애드온에 의해 EKS 클러스터에 생성된 것들을 살펴보겠습니다. `kube-system` 네임스페이스에 배포된 DaemonSet을 볼 수 있으며, 이는 클러스터의 각 노드에서 Pod를 실행합니다.

```bash
$ kubectl -n kube-system get daemonset eks-pod-identity-agent
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
eks-pod-identity-agent    3         3         3       3            3           <none>          3d21h
$ kubectl -n kube-system get pods -l app.kubernetes.io/name=eks-pod-identity-agent
NAME                           READY   STATUS    RESTARTS   AGE
eks-pod-identity-agent-4tn28   1/1     Running   0          3d21h
eks-pod-identity-agent-hslc5   1/1     Running   0          3d21h
eks-pod-identity-agent-thvf5   1/1     Running   0          3d21h
```

`carts` 서비스가 DynamoDB 테이블에서 읽고 쓰는 데 필요한 권한을 제공하는 IAM role은 이 모듈의 첫 번째 단계에서 `prepare-environment` 스크립트를 실행할 때 생성되었습니다. 아래와 같이 정책을 확인할 수 있습니다:

```bash
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts",
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/*"
      ],
      "Sid": "AllAPIActionsOnCart"
    }
  ],
  "Version": "2012-10-17"
}
```

이 role은 EKS Service Principal이 Pod Identity를 위해 이 role을 assume할 수 있도록 적절한 신뢰 관계로 구성되어 있습니다. 아래 명령어로 확인할 수 있습니다:

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
```

다음으로, Amazon EKS Pod Identity 기능을 사용하여 배포에서 사용할 Kubernetes Service Account와 AWS IAM role을 연결하겠습니다. 연결을 생성하려면 다음 명령어를 실행하세요:

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
{
    "association": {
        "clusterName": "eks-workshop",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo",
        "associationArn": "arn:aws::1234567890:podidentityassociation/eks-workshop/a-abcdefghijklmnop1",
        "associationId": "a-abcdefghijklmnop1",
        "tags": {},
        "createdAt": "2024-01-09T16:16:38.163000+00:00",
        "modifiedAt": "2024-01-09T16:16:38.163000+00:00"
    }
}
```

이제 `carts` Deployment가 `carts` Service Account를 사용하고 있는지 확인하면 됩니다:

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

Service Account가 확인되었으니 `carts` Pod를 재시작해 보겠습니다:

```bash hook=enable-pod-identity hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

이제 다음 섹션에서 carts 애플리케이션에 대해 발생했던 DynamoDB 권한 문제가 해결되었는지 확인해 보겠습니다.

