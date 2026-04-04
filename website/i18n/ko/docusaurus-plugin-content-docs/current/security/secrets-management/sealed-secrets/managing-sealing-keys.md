---
title: "Sealing Key 관리"
sidebar_position: 434
tmdTranslationSourceHash: 'a072117fa3ec03e6c678452d1cc60a39'
---

SealedSecret 내의 암호화된 데이터를 복호화할 수 있는 유일한 방법은 컨트롤러가 관리하는 sealing key를 사용하는 것입니다. 재해 발생 후 클러스터의 원래 상태를 복원하려고 하거나 GitOps 워크플로를 활용하여 Git 리포지토리에서 SealedSecrets를 포함한 Kubernetes 리소스를 배포하고 새 EKS 클러스터를 생성하려는 상황이 있을 수 있습니다. 새 EKS 클러스터에 배포된 컨트롤러는 SealedSecrets를 unsealing할 수 있도록 동일한 sealing key를 사용해야 합니다.

다음 명령을 실행하여 클러스터에서 sealing key를 가져옵니다. 프로덕션 환경에서는 이 작업을 수행하는 데 필요한 권한을 제한된 클라이언트 집합에만 부여하기 위해 Kubernetes RBAC를 활용하는 것이 모범 사례로 간주됩니다.

```bash
$ kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml \
  > /tmp/master-sealing-key.yaml
```

작업을 테스트하기 위해 sealing key가 포함된 Secret을 삭제하고 sealed secrets 컨트롤러를 재시작해 보겠습니다:

```bash
$ kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key
$ kubectl -n kube-system delete pod -l name=sealed-secrets-controller
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

이제 컨트롤러의 로그를 확인해보겠습니다. SealedSecret을 복호화하는 데 실패한 것을 확인할 수 있습니다:

```bash
$ kubectl logs deployment/sealed-secrets-controller -n kube-system
[...]
2022/11/18 22:47:42 Updating catalog/catalog-sealed-db
2022/11/18 22:47:43 Error updating catalog/catalog-sealed-db, giving up: no key could decrypt secret (password, username, endpoint, name)
E1118 22:47:43.030178       1 controller.go:175] no key could decrypt secret (password, username, endpoint, name)
2022/11/18 22:47:43 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a6705e6f-72a1-43f5-8c0b-4f45b9b6f5fb", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"519192", FieldPath:""}): type: 'Warning' reason: 'ErrUnsealFailed' Failed to unseal: no key could decrypt secret (password, username, endpoint, name)
```

이는 sealing key를 삭제했기 때문이며, 컨트롤러가 시작할 때 새로운 키를 생성했습니다. 이로 인해 이 컨트롤러가 모든 SealedSecret 리소스에 효과적으로 접근할 수 없게 됩니다. 다행히 이전에 `/tmp/master-sealing-key.yaml`에 저장해두었으므로 EKS 클러스터에서 다시 생성할 수 있습니다:

```bash
$ kubectl apply -f /tmp/master-sealing-key.yaml
$ kubectl -n kube-system delete pod -l name=sealed-secrets-controller
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

로그를 다시 확인하면 이번에는 컨트롤러가 복원한 sealing key를 가져와서 `catalog-sealed-db` Secret을 unsealing했음을 보여줍니다:

```bash
$ kubectl logs deployment/sealed-secrets-controller -n kube-system
[...]
2022/11/18 22:52:51 Updating catalog/catalog-sealed-db
2022/11/18 22:52:51 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a6705e6f-72a1-43f5-8c0b-4f45b9b6f5fb", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"519192", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

`/tmp/master-sealing-key.yaml` 파일에는 컨트롤러가 생성한 공개/개인 키 쌍이 포함되어 있습니다. 이 파일이 유출되면 모든 SealedSecret 매니페스트가 unsealing될 수 있고 저장된 암호화된 민감 정보가 노출될 수 있습니다. 따라서 이 파일은 최소 권한 액세스를 부여하여 보호해야 합니다. sealing key 갱신 및 수동 sealing key 관리와 같은 주제에 대한 추가 지침은 [문서](https://github.com/bitnami-labs/sealed-secrets#secret-rotation)를 참조하세요.

sealing key를 보호하는 한 가지 옵션은 `/tmp/master-sealing-key.yaml` 파일 내용을 AWS Systems Manager Parameter Store에 SecureString 파라미터로 저장하는 것입니다. 파라미터는 KMS Customer managed key(CMK)를 사용하여 보호할 수 있으며, Key 정책을 사용하여 파라미터를 검색하기 위해 이 키를 사용할 수 있는 IAM 주체 집합을 제한할 수 있습니다. 또한 KMS에서 이 CMK의 자동 교체를 활성화할 수도 있습니다. 표준 계층 파라미터는 최대 4096자의 파라미터 값을 지원합니다. 따라서 master.yaml 파일의 크기를 고려할 때 Advanced 계층의 파라미터로 저장해야 합니다.

