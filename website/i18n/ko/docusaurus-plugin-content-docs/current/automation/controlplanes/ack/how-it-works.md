---
title: "ACK는 어떻게 작동하나요?"
sidebar_position: 5
tmdTranslationSourceHash: 'dab1dfb1b518410df47bf95ab800501e'
---

:::info
kubectl은 또한 포맷된 출력 대신 배포 정의의 전체 YAML 또는 JSON 매니페스트를 추출하는 유용한 `-oyaml` 및 `-ojson` 플래그를 제공합니다.
:::

이 컨트롤러는 `dynamodb.services.k8s.aws.Table`과 같은 DynamoDB에 특정한 Kubernetes Custom Resource를 감시합니다. 이러한 리소스의 구성을 기반으로 DynamoDB 엔드포인트에 API 호출을 수행합니다. 리소스가 생성되거나 수정되면 컨트롤러는 `Status` 필드를 채워서 Custom Resource의 상태를 업데이트합니다. 매니페스트 사양에 대한 자세한 내용은 [ACK 레퍼런스 문서](https://aws-controllers-k8s.github.io/community/reference/)를 참조하세요.

컨트롤러가 수신하는 객체 및 API 호출에 대한 더 깊은 통찰력을 얻으려면 다음을 실행할 수 있습니다:

```bash
$ kubectl get crd
```

이 명령은 ACK 및 DynamoDB와 관련된 것을 포함하여 클러스터의 모든 Custom Resource Definition(CRD)을 표시합니다.

