---
title: "Pod IAM 이해하기"
sidebar_position: 23
tmdTranslationSourceHash: '921036b29d3f3d09674d38d5fde46585'
---

문제를 파악하기 위해 가장 먼저 살펴볼 곳은 `carts` 서비스의 로그입니다:

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

애플리케이션이 오류를 생성하고 있으며, 이는 Pod가 DynamoDB에 액세스하는 데 사용하는 IAM role에 필요한 권한이 없음을 나타냅니다. 이는 기본적으로 Pod에 IAM role이나 정책이 연결되어 있지 않은 경우, Pod가 실행 중인 EC2 인스턴스에 할당된 인스턴스 프로파일에 연결된 IAM role을 사용하기 때문에 발생하는 것입니다. 이 경우 해당 role에는 DynamoDB에 대한 액세스를 허용하는 IAM 정책이 없습니다.

이 문제를 해결하는 한 가지 방법은 EC2 워커 노드의 IAM 권한을 확장하는 것이지만, 이렇게 하면 노드에서 실행되는 모든 Pod가 DynamoDB 테이블에 액세스할 수 있게 되어 보안 모범 사례를 반영하지 못합니다. 대신 IAM Roles for Service Accounts (IRSA)를 사용하여 `carts` 서비스의 Pod에만 특별히 액세스를 허용하겠습니다.

