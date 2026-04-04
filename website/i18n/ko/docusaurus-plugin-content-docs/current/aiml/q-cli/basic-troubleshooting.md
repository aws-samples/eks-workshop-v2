---
title: "기본 트러블슈팅"
sidebar_position: 22
tmdTranslationSourceHash: '03ee20963e11dce2e6077f5b777cc5d3'
---

이 섹션에서는 Amazon Q CLI와 [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/)를 사용하여 EKS 클러스터의 문제를 트러블슈팅합니다.

먼저 클러스터에 실패하는 Pod를 배포한 다음, Amazon Q CLI를 사용하여 트러블슈팅을 진행하겠습니다.

::yaml{file="manifests/modules/aiml/q-cli/troubleshoot/failing-pod.yaml"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml
```

Pod의 상태를 확인합니다:

```bash
$ kubectl get pods -n default
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   0/1     Pending   0          5m29s
```

보시다시피 클러스터에 pending 상태의 Pod가 있습니다. Q CLI를 사용하여 원인을 조사해 보겠습니다.

새로운 Q CLI 세션을 시작합니다:

```bash test=false
$ q chat
```

Q CLI에 문제 트러블슈팅을 요청하기 위해 다음 질문을 입력합니다:

```text
I have a pod stuck in a pending state in my eks-workshop cluster. Find the cause of the failure and provide me with a summary of the approach to solve it.
```

프롬프트를 처리하기 위해 Q CLI는 MCP 서버의 다양한 도구를 사용합니다. 수행할 수 있는 단계는 다음과 같습니다:

- `list_k8s_resources` 도구를 사용하여 클러스터에서 실패한 Pod 식별
- `manage_k8s_resource` 도구를 사용하여 Pod의 세부 정보 가져오기
- `get_k8s_events` 도구를 사용하여 Pod의 Kubernetes 이벤트 기록 검사
- `manage_k8s_resource` 도구를 사용하여 관련 Kubernetes 리소스의 세부 정보 가져오기
- `search_eks_troubleshoot_guide` 도구를 사용하여 EKS 트러블슈팅 가이드 검색 및 참조

Q CLI는 클러스터에서 수집한 데이터를 기반으로 분석을 제공합니다.

<details>
  <summary>샘플 응답 확장</summary>

```text
## Pod Pending Issue Summary

Problem: Pod failing-pod in the default namespace is stuck in pending state.

Root Cause: The pod references a PersistentVolumeClaim named my-pvc that doesn't exist.

Error Details:
• Status: Unschedulable
• Message: persistentvolumeclaim "my-pvc" not found
• 0/3 nodes available due to missing PVC

Solutions:
1. Create the missing PVC - Create a PersistentVolumeClaim named my-pvc using the available gp2 StorageClass
2. Remove the volume requirement - Edit the pod to remove the volume mount and PVC reference
3. Delete the pod - If it's a test pod that's no longer needed

Available Resources:
• StorageClass gp2 is available for creating PVCs
• 3 worker nodes are healthy and available

The pod will automatically schedule once the PVC is created or the volume requirement is removed.
```

</details>

Q CLI 세션을 종료하려면 다음을 입력합니다:

```text
/quit
```

이제 실패한 Pod를 제거합니다:

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/failing-pod.yaml --ignore-not-found
```

다음 섹션에서는 더 복잡한 트러블슈팅 시나리오를 살펴보겠습니다.

