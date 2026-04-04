---
title: "AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 422
tmdTranslationSourceHash: ea479b4d3aff83a8f822a98785b759ca
---

[이전 단계](./index.md)에서 실행한 `prepare-environment` 스크립트는 이 실습에 필요한 Kubernetes Secrets Store CSI Driver용 AWS Secrets and Configuration Provider(ASCP)를 이미 설치했습니다.

애드온이 올바르게 배포되었는지 확인해 보겠습니다.

먼저 Secret Store CSI driver `DaemonSet`과 그 `Pod`들을 확인합니다:

```bash
$ kubectl -n kube-system get pods,daemonsets -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-k7m6c   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-x2rs4   3/3     Running   0          3m57s
```

다음으로 CSI Secrets Store Provider for AWS driver `DaemonSet`과 그 `Pod`들을 확인합니다:

```bash
$ kubectl -n kube-system get pods,daemonset -l "app=secrets-store-csi-driver-provider-aws"
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-djtf5   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-dzg9r   1/1     Running   0          2m2s
```

CSI 드라이버를 통해 AWS Secrets Manager에 저장된 시크릿에 대한 액세스를 제공하려면 `SecretProviderClass`가 필요합니다. 이는 AWS Secrets Manager의 정보와 일치하는 드라이버 구성 및 파라미터를 제공하는 네임스페이스 범위의 커스텀 리소스입니다.

::yaml{file="manifests/modules/security/secrets-manager/secret-provider-class.yaml" paths="spec.provider,spec.parameters.objects,spec.secretObjects.0"}

1. `provider: aws`는 AWS Secrets Store CSI driver를 지정합니다
2. `parameters.objects`는 `$SECRET_NAME`이라는 이름의 AWS `secretsmanager` 소스 시크릿을 정의하고 [jmesPath](https://jmespath.org/)를 사용하여 특정 `username`과 `password` 필드를 Kubernetes에서 사용할 수 있도록 명명된 별칭으로 추출합니다
3. `secretObjects`는 추출된 `username`과 `password` 필드를 시크릿 키에 매핑하는 `catalog-secret`이라는 표준 `Opaque` Kubernetes 시크릿을 생성합니다

이 리소스를 생성해 보겠습니다:

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

Secret Store CSI Driver는 Kubernetes와 AWS Secrets Manager와 같은 외부 시크릿 공급자 사이의 중개자 역할을 합니다. SecretProviderClass로 구성하면 Pod 볼륨에 시크릿을 파일로 마운트하고 동기화된 Kubernetes Secret 객체를 생성할 수 있어, 애플리케이션이 이러한 시크릿을 사용하는 방법에 유연성을 제공합니다.

