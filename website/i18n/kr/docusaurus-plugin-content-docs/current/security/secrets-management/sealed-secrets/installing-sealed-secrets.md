---
title: "Sealed Secrets 설치하기"
sidebar_position: 432
---

`kubeseal` CLI는 sealed secrets 컨트롤러와 상호작용하는데 사용되며, 이미 IDE에 설치되어 있습니다.

먼저 EKS 클러스터에 sealed secrets 컨트롤러를 설치하겠습니다:

```bash
$ kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

이제 파드의 상태를 확인하겠습니다

```bash
$ kubectl get pods -n kube-system -l name=sealed-secrets-controller
sealed-secrets-controller-77747c4b8c-snsxp      1/1     Running   0          5s
```

sealed secrets 컨트롤러의 로그를 보면 컨트롤러가 시작 시 기존 프라이빗 키를 찾으려 시도하는 것을 확인할 수 있습니다. 프라이빗 키가 발견되지 않으면, 인증서 세부 정보가 포함된 새로운 시크릿을 생성합니다.

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system
controller version: 0.18.0
2022/10/18 09:17:01 Starting sealed-secrets controller version: 0.18.0
2022/10/18 09:17:01 Searching for existing private keys
2022/10/18 09:17:02 New key written to kube-system/sealed-secrets-keyvkl9w
2022/10/18 09:17:02 Certificate is
-----BEGIN CERTIFICATE-----
MIIEzTCCArWgAwIBAgIRAPsk+UrW9GlPu4gXN1qKqGswDQYJKoZIhvcNAQELBQAw
ADAeFw0yMjEwMTgwOTE3MDJaFw0zMjEwMTUwOTE3MDJaMAAwggIiMA0GCSqGSIb3
(...)
q5P11EvxPBfIt9xDx5Jz4JWp5M7wWawGaeBqTmTDbSkc
-----END CERTIFICATE-----

2022/10/18 09:17:02 HTTP server serving on :8080
```

시크릿의 내용을 확인할 수 있으며, 이는 YAML 형식의 공개/비공개 키 쌍으로 된 봉인 키를 포함하고 있습니다:

```bash
$ kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    tls.crt: LS0tL(...)LQo=
    tls.key: LS0tL(...)LS0K
  kind: Secret
  metadata:
    creationTimestamp: "2022-10-18T09:17:02Z"
    generateName: sealed-secrets-key
    labels:
      sealedsecrets.bitnami.com/sealed-secrets-key: active
    name: sealed-secrets-keyvkl9w
    namespace: kube-system
    resourceVersion: "129381"
    uid: 23f5e70c-2537-4c38-a85c-b410f1dcf9a6
  type: kubernetes.io/tls
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```