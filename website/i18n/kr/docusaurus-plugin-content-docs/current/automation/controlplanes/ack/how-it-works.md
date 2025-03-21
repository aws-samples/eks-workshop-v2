---
title: "ACK는 어떻게 작동하나요?"
sidebar_position: 5
---

:::info
kubectl은 또한 유용한 `-oyaml`과 `-ojson` 플래그를 제공하는데, 이는 형식이 지정된 출력 대신 배포 정의의 전체 YAML 또는 JSON 매니페스트를 각각 추출합니다.
:::

이 컨트롤러는 `dynamodb.services.k8s.aws.Table`과 같은 DynamoDB 관련 Kubernetes 커스텀 리소스를 감시합니다. 이러한 리소스의 구성을 기반으로 DynamoDB 엔드포인트에 API 호출을 수행합니다. 리소스가 생성되거나 수정되면, 컨트롤러는 `Status` 필드를 채워 커스텀 리소스의 상태를 업데이트합니다. 매니페스트 사양에 대한 자세한 내용은 [ACK 참조 문서](https://aws-controllers-k8s.github.io/community/reference/)를 참조하세요.

컨트롤러가 수신하는 객체와 API 호출에 대해 더 자세히 알아보려면 다음을 실행할 수 있습니다:

```bash
$ kubectl get crd
```

이 명령은 ACK와 DynamoDB 관련 항목을 포함하여 클러스터의 모든 커스텀 리소스 정의(CRD)를 표시합니다.