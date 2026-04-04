---
title: "Pod IAM 이해하기"
sidebar_position: 33
tmdTranslationSourceHash: '8fc870acc614f97786463eea6ee471a4'
---

문제를 찾기 위한 첫 번째 장소는 `carts` 서비스의 로그입니다:

```bash hook=pod-logs
$ LATEST_POD=$(kubectl get pods -n carts --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
$ kubectl logs -n carts -p $LATEST_POD
[...]
***************************
APPLICATION FAILED TO START
***************************

Description:

An error occurred when accessing Amazon DynamoDB:

User: arn:aws:sts::1234567890:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-rjjGEigUX8KZ/i-01f378b057326852a is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action (Service: DynamoDb, Status Code: 400, Request ID: PUIFHHTQ7SNQVERCRJ6VHT8MBBVV4KQNSO5AEMVJF66Q9ASUAAJG)

Action:

Check that the DynamoDB table has been created and your IAM credentials are configured with the appropriate access.
```

애플리케이션은 DynamoDB에 액세스하기 위해 Pod가 사용하는 IAM 역할에 필요한 권한이 없음을 나타내는 오류를 생성하고 있습니다. 이는 기본적으로 IAM 역할이나 정책이 Pod에 연결되지 않은 경우, Pod가 실행 중인 EC2 인스턴스 프로파일에 연결된 IAM 역할을 사용하기 때문에 발생합니다. 이 경우 해당 역할에는 DynamoDB에 대한 액세스를 허용하는 IAM 정책이 없습니다.

한 가지 접근 방식은 EC2 인스턴스 프로파일의 IAM 권한을 확장하는 것이지만, 이렇게 하면 해당 인스턴스에서 실행되는 모든 Pod가 우리의 DynamoDB 테이블에 액세스할 수 있게 됩니다. 이는 최소 권한 원칙을 위반하며 보안 모범 사례가 아닙니다. 대신, EKS Pod Identity를 사용하여 `carts` 애플리케이션이 Pod 수준에서 필요로 하는 특정 권한을 제공하여 세밀한 액세스 제어를 보장할 것입니다.

