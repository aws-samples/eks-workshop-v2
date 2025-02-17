---
title: "소개"
sidebar_position: 3
---

각 ACK 서비스 컨트롤러는 개별 ACK 서비스 컨트롤러에 해당하는 공개 리포지토리에 게시되는 별도의 컨테이너 이미지로 패키징됩니다. 프로비저닝하고자 하는 각 AWS 서비스에 대해, 해당 컨트롤러의 리소스가 Amazon EKS 클러스터에 설치되어야 합니다. ACK를 위한 Helm 차트와 공식 컨테이너 이미지는 [여기](https://gallery.ecr.aws/aws-controllers-k8s)에서 확인할 수 있습니다.

이 섹션에서는 Amazon DynamoDB ACK를 사용할 것이므로, 먼저 Helm 차트를 사용하여 해당 ACK 컨트롤러를 설치해야 합니다:

```bash wait=60
$ aws ecr-public get-login-password --region us-east-1 | \
  helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install ack-dynamodb  \
  oci://public.ecr.aws/aws-controllers-k8s/dynamodb-chart \
  --version=${DYNAMO_ACK_VERSION} \
  --namespace ack-system --create-namespace \
  --set "aws.region=${AWS_REGION}" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$ACK_IAM_ROLE" \
  --wait
```

컨트롤러는 `ack-system` 네임스페이스에서 디플로이먼트로 실행됩니다:

```bash
$ kubectl get deployment -n ack-system
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
ack-dynamodb-dynamodb-chart   1/1     1            1           13s
```