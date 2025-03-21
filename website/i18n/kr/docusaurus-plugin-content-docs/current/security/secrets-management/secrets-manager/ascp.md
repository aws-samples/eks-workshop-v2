---
title: "AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 422
---

[이전 단계](./index.md)에서 실행한 `prepare-environment` 스크립트는 이미 이 실습에 필요한 Kubernetes Secrets Store CSI Driver용 AWS Secrets and Configuration Provider (ASCP)를 설치했습니다.

애드온이 올바르게 배포되었는지 확인해 보겠습니다.

먼저, Secret Store CSI 드라이버 `DaemonSet`과 해당 `Pods`를 확인합니다:

```bash
$ kubectl -n secrets-store-csi-driver get pods,daemonsets -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-k7m6c   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-x2rs4   3/3     Running   0          3m57s
```

다음으로, AWS 드라이버용 CSI Secrets Store Provider `DaemonSet`과 해당 `Pods`를 확인합니다:

```bash
$ kubectl -n kube-system get pods,daemonset -l "app=secrets-store-csi-driver-provider-aws"
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-djtf5   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-dzg9r   1/1     Running   0          2m2s
```

CSI 드라이버를 통해 AWS Secrets Manager에 저장된 시크릿에 접근하려면 _SecretProviderClass_가 필요합니다 - 이는 드라이버 구성과 AWS Secrets Manager의 정보와 일치하는 특정 매개변수를 제공하는 네임스페이스가 지정된 사용자 정의 리소스입니다.

```file
manifests/modules/security/secrets-manager/secret-provider-class.yaml
```

이 리소스를 생성하고 두 가지 주요 구성 섹션을 살펴보겠습니다:

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

첫째, _objects_ 매개변수는 다음 단계에서 AWS Secrets Manager에 저장할 `eks-workshop/catalog-secret`이라는 시크릿을 가리킵니다. [jmesPath](https://jmespath.org/)를 사용하여 JSON 형식의 시크릿에서 특정 Key-Value 쌍을 추출하고 있습니다:

```bash
$ kubectl get secretproviderclass -n catalog catalog-spc -o yaml | yq '.spec.parameters.objects'

- objectName: "eks-workshop/catalog-secret"
  objectType: "secretsmanager"
  jmesPath:
    - path: username
      objectAlias: username
    - path: password
      objectAlias: password
```

둘째, _secretObjects_ 섹션은 AWS Secrets Manager 시크릿의 데이터로 Kubernetes 시크릿을 생성하고 동기화하는 방법을 정의합니다. Pod에 마운트될 때, SecretProviderClass는 `catalog-secret`이라는 이름의 Kubernetes Secret을 생성하고(존재하지 않는 경우) AWS Secrets Manager의 값과 동기화합니다:

```bash
$ kubectl get secretproviderclass -n catalog catalog-spc -o yaml | yq '.spec.secretObjects'

- data:
    - key: username
      objectName: username
    - key: password
      objectName: password
  secretName: catalog-secret
  type: Opaque
```