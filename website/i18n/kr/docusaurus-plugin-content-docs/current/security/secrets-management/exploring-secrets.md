---
title: "시크릿 탐색하기"
sidebar_position: 41
---

Kubernetes 시크릿은 환경 변수나 볼륨과 같은 다양한 방법으로 Pod에 노출될 수 있습니다.

### 환경 변수로 시크릿 노출하기

database-credentials 시크릿의 username과 password라는 키를 아래와 같이 Pod 매니페스트를 사용하여 Pod의 환경 변수로 노출할 수 있습니다:

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

### 볼륨으로 시크릿 노출하기

시크릿은 Pod에 데이터 볼륨으로 마운트될 수도 있으며, 아래와 같이 Pod 매니페스트를 사용하여 시크릿 키가 프로젝트되는 볼륨 내의 경로를 제어할 수 있습니다:

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

위의 Pod 명세를 사용하면 다음과 같은 결과가 발생합니다:

- database-credentials 시크릿의 username 키에 대한 값이 Pod 내의 `/etc/data/DATABASE_USER` 파일에 저장됩니다
- password 키에 대한 값이 `/etc/data/DATABASE_PASSWORD` 파일에 저장됩니다