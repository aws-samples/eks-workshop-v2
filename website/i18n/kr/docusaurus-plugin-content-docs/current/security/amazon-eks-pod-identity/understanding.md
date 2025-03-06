---
title: "Pod IAM 이해하기"
sidebar_position: 33
---

문제를 확인하기 위한 첫 번째 단계는 `carts` 서비스의 로그를 확인하는 것입니다:

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

애플리케이션에서 발생하는 오류는 DynamoDB에 접근하기 위해 우리의 Pod가 사용하는 IAM 역할이 필요한 권한을 가지고 있지 않다는 것을 나타냅니다. 이는 Pod에 IAM 역할이나 정책이 연결되어 있지 않을 경우, 기본적으로 Pod가 실행되는 EC2 인스턴스에 할당된 인스턴스 프로파일에 연결된 IAM 역할을 사용하기 때문에 발생합니다. 이 경우 해당 역할은 DynamoDB 접근을 허용하는 IAM 정책을 가지고 있지 않습니다.

이 문제를 해결하는 한 가지 방법은 EC2 인스턴스 프로파일의 IAM 권한을 확장하는 것이지만, 이렇게 하면 해당 인스턴스에서 실행되는 모든 Pod가 DynamoDB 테이블에 접근할 수 있게 되어 보안상 좋지 않으며, 최소 권한 원칙을 부여하는 좋은 방법이 아닙니다. 대신 EKS Pod Identity를 사용하여 Pod 수준에서 `carts` 애플리케이션에 필요한 특정 접근 권한을 허용할 것입니다.