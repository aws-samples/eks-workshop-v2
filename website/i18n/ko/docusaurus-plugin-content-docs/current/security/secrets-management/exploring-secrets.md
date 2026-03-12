---
title: "Secret 살펴보기"
sidebar_position: 41
tmdTranslationSourceHash: '7d847c17384f27a8edfe40c26afe31f6'
---

Kubernetes Secret은 환경 변수와 볼륨 등 다양한 방법으로 Pod에 노출될 수 있습니다.

### 환경 변수로 Secret 노출하기

다음과 같은 Pod 매니페스트를 사용하여 database-credentials Secret의 키인 username과 password를 Pod에 환경 변수로 노출할 수 있습니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: someName
  namespace: someNamespace
spec:
  containers:
    - name: someContainer
      image: someImage
      env:
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: username
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: password
```

### 볼륨으로 Secret 노출하기

Secret은 Pod에 데이터 볼륨으로 마운트할 수도 있으며, 다음과 같은 Pod 매니페스트를 사용하여 볼륨 내에서 Secret 키가 프로젝션되는 경로를 제어할 수 있습니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: someName
  namespace: someNamespace
spec:
  containers:
    - name: someContainer
      image: someImage
      volumeMounts:
        - name: secret-volume
          mountPath: "/etc/data"
          readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: database-credentials
        items:
          - key: username
            path: DATABASE_USER
          - key: password
            path: DATABASE_PASSWORD
```

위의 Pod 사양을 사용하면 다음과 같은 결과가 발생합니다:

- database-credentials Secret의 username 키 값은 Pod 내의 `/etc/data/DATABASE_USER` 파일에 저장됩니다
- password 키 값은 `/etc/data/DATABASE_PASSWORD` 파일에 저장됩니다

