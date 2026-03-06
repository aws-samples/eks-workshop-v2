---
title: StatefulSets
sidebar_position: 10
tmdTranslationSourceHash: 29ae0d08e36a7abcf762a90da75bf1fa
---

Deployment와 마찬가지로 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)은 동일한 컨테이너 스펙을 기반으로 하는 Pod를 관리합니다. Deployment와 달리 StatefulSet은 각 Pod에 대해 고유한 식별자를 유지합니다. 이러한 Pod는 동일한 스펙에서 생성되지만 서로 교체할 수 없으며, 각 Pod는 재스케줄링 이벤트가 발생해도 유지되는 영구적인 식별자를 갖습니다.

워크로드에 대해 지속성을 제공하기 위해 스토리지 볼륨을 사용하려면 솔루션의 일부로 StatefulSet을 사용할 수 있습니다. StatefulSet의 개별 Pod는 장애에 취약하지만, 영구적인 Pod 식별자를 통해 기존 볼륨을 장애가 발생한 Pod를 대체하는 새 Pod에 더 쉽게 연결할 수 있습니다.

StatefulSet은 다음 중 하나 이상이 필요한 애플리케이션에 유용합니다:

- 안정적이고 고유한 네트워크 식별자
- 안정적이고 영구적인 스토리지
- 순서가 지정된 우아한 배포 및 스케일링
- 순서가 지정된 자동화된 롤링 업데이트

ecommerce 애플리케이션에는 Catalog 마이크로서비스의 일부로 이미 배포된 StatefulSet이 있습니다. Catalog 마이크로서비스는 EKS에서 실행되는 MySQL 데이터베이스를 활용합니다. 데이터베이스는 **영구 스토리지**가 필요하기 때문에 StatefulSet 사용의 좋은 예입니다. MySQL Database Pod를 분석하여 현재 볼륨 구성을 확인할 수 있습니다:

```bash
$ kubectl describe statefulset -n catalog catalog-mysql
Name:               catalog-mysql
Namespace:          catalog
[...]
  Containers:
   mysql:
    Image:      public.ecr.aws/docker/library/mysql:8.0
    Port:       3306/TCP
    Host Port:  0/TCP
    Environment:
      MYSQL_ROOT_PASSWORD:  my-secret-pw
      MYSQL_USER:           <set to the key 'username' in secret 'catalog-db'>  Optional: false
      MYSQL_PASSWORD:       <set to the key 'password' in secret 'catalog-db'>  Optional: false
      MYSQL_DATABASE:       <set to the key 'name' in secret 'catalog-db'>      Optional: false
    Mounts:
      /var/lib/mysql from data (rw)
  Volumes:
   data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
Volume Claims:  <none>
[...]
```

보시다시피 StatefulSet의 [`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) 섹션은 "Pod의 수명을 공유하는" [EmptyDir 볼륨 타입](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)만 사용하고 있음을 보여줍니다.

![MySQL with emptyDir](/docs/fundamentals/storage/ebs/mysql-emptydir.webp)

`emptyDir` 볼륨은 Pod가 노드에 할당될 때 처음 생성되며, 해당 Pod가 노드에서 실행되는 동안 존재합니다. 이름에서 알 수 있듯이 emptyDir 볼륨은 처음에 비어 있습니다. Pod의 모든 컨테이너는 emptyDir 볼륨의 동일한 파일을 읽고 쓸 수 있지만, 해당 볼륨은 각 컨테이너에서 동일하거나 다른 경로에 마운트될 수 있습니다. **어떤 이유로든 Pod가 노드에서 제거되면 emptyDir의 데이터는 영구적으로 삭제됩니다.** 따라서 EmptyDir은 MySQL Database에 적합하지 않습니다.

MySQL 컨테이너 내부에서 셸 세션을 시작하고 테스트 파일을 생성하여 이를 증명할 수 있습니다. 그런 다음 StatefulSet에서 실행 중인 Pod를 삭제합니다. Pod가 emptyDir을 사용하고 Persistent Volume (PV)이 아니기 때문에 파일은 Pod 재시작 후 유지되지 않습니다. 먼저 MySQL 컨테이너 내부에서 명령을 실행하여 emptyDir `/var/lib/mysql` 경로(MySQL이 데이터베이스 파일을 저장하는 곳)에 파일을 생성해 보겠습니다:

```bash
$ kubectl exec catalog-mysql-0 -n catalog -- bash -c  "echo 123 > /var/lib/mysql/test.txt"
```

이제 `/var/lib/mysql` 디렉토리에 `test.txt` 파일이 생성되었는지 확인해 보겠습니다:

```bash
$ kubectl exec catalog-mysql-0 -n catalog -- ls -larth /var/lib/mysql/ | grep -i test
-rw-r--r-- 1 root  root     4 Oct 18 13:38 test.txt
```

이제 현재 `catalog-mysql` Pod를 제거해 보겠습니다. 이렇게 하면 StatefulSet 컨트롤러가 자동으로 새 catalog-mysql Pod를 다시 생성하게 됩니다:

```bash
$ kubectl delete pods -n catalog -l app.kubernetes.io/component=mysql
pod "catalog-mysql-0" deleted
```

몇 초 기다린 후 아래 명령을 실행하여 `catalog-mysql` Pod가 다시 생성되었는지 확인합니다:

```bash
$ kubectl wait --for=condition=Ready pod -n catalog \
  -l app.kubernetes.io/component=mysql --timeout=30s
pod/catalog-mysql-0 condition met
$ kubectl get pods -n catalog -l app.kubernetes.io/component=mysql
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          29s
```

마지막으로 MySQL 컨테이너 셸로 다시 접속하여 `/var/lib/mysql` 경로에서 `ls` 명령을 실행하여 이전에 생성한 `test.txt` 파일을 찾아봅시다:

```bash expectError=true
$ kubectl exec catalog-mysql-0 -n catalog -- cat /var/lib/mysql/test.txt
cat: /var/lib/mysql/test.txt: No such file or directory
command terminated with exit code 1
```

보시다시피 `emptyDir` 볼륨이 임시적이기 때문에 `test.txt` 파일이 더 이상 존재하지 않습니다. 다음 섹션에서는 동일한 실험을 실행하고 Persistent Volume (PV)이 `test.txt` 파일을 어떻게 유지하고 Pod 재시작 및/또는 장애 시 생존하는지 보여드리겠습니다.

다음 페이지에서는 Kubernetes의 스토리지와 AWS 클라우드 생태계와의 통합에 대한 주요 개념을 이해하는 작업을 진행하겠습니다.

