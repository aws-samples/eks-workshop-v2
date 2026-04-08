---
title: "シークレットの探索"
sidebar_position: 41
tmdTranslationSourceHash: 7d847c17384f27a8edfe40c26afe31f6
---

Kubernetesのシークレットは、環境変数やボリュームなど、さまざまな方法でポッドに公開することができます。

### シークレットを環境変数として公開する

以下のようなポッドマニフェストを使用して、database-credentialsシークレットのキー（usernameとpassword）をポッドの環境変数として公開することができます：

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

### シークレットをボリュームとして公開する

シークレットはポッドにデータボリュームとしてマウントすることもでき、以下のようなポッドマニフェストを使用して、ボリューム内のシークレットキーが投影されるパスを制御できます：

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

上記のポッド仕様では、以下のことが起こります：

- database-credentialsシークレットのusernameキーの値は、ポッド内の`/etc/data/DATABASE_USER`ファイルに格納されます
- passwordキーの値は、`/etc/data/DATABASE_PASSWORD`ファイルに格納されます
