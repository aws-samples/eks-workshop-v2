---
title: StatefulSets
sidebar_position: 10
tmdTranslationSourceHash: 29ae0d08e36a7abcf762a90da75bf1fa
---

Deploymentと同様に、[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)は同一のコンテナスペックに基づいたPodを管理します。Deploymentとは異なり、StatefulSetは各Podに固有のIDを維持します。これらのPodは同じ仕様から作成されますが、互換性がなく、それぞれが再スケジューリングイベントの間も維持される永続的な識別子を持っています。

ワークロードに永続性を提供するためにストレージボリュームを使用したい場合は、StatefulSetをソリューションの一部として使用できます。StatefulSetの個々のPodは障害の影響を受けやすいですが、永続的なPod識別子があることで、障害が発生したPodを置き換える新しいPodに既存のボリュームをマッチさせることが容易になります。

StatefulSetは、以下のうち1つ以上を必要とするアプリケーションに価値があります：

- 安定した一意のネットワーク識別子
- 安定した永続的なストレージ
- 順序付けられた優雅なデプロイメントとスケーリング
- 順序付けられた自動ローリングアップデート

私たちのEコマースアプリケーションでは、Catalogマイクロサービスの一部としてすでにStatefulSetがデプロイされています。CatalogマイクロサービスはEKS上で実行されているMySQLデータベースを利用しています。データベースは**永続的なストレージ**を必要とするため、StatefulSetの使用例として最適です。MySQLデータベースPodを分析して、現在のボリューム構成を確認してみましょう：

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

StatefulSetの[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example)セクションを見ると、「Podのライフタイムを共有する」[EmptyDirボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)のみを使用していることがわかります。

![MySQL with emptyDir](/docs/fundamentals/storage/ebs/mysql-emptydir.webp)

`emptyDir`ボリュームは、Podがノードに割り当てられたときに最初に作成され、そのPodがそのノードで実行されている限り存在します。名前が示すように、emptyDirボリュームは最初は空です。Podのすべてのコンテナは、同じemptyDirボリュームの同じファイルを読み書きできますが、そのボリュームは各コンテナで同じまたは異なるパスにマウントできます。**Podが何らかの理由でノードから削除されると、emptyDirのデータは永久に削除されます。**したがって、EmptyDirは私たちのMySQLデータベースには適していません。

これを実証するために、MySQLコンテナ内でシェルセッションを開始してテストファイルを作成してみましょう。その後、StatefulSetで実行されているPodを削除します。Podが永続ボリューム（PV）ではなくemptyDirを使用しているため、ファイルはPodの再起動後に残りません。まず、MySQLコンテナ内でemptyDir `/var/lib/mysql`パス（MySQLがデータベースファイルを保存する場所）にファイルを作成するコマンドを実行しましょう：

```bash
$ kubectl exec catalog-mysql-0 -n catalog -- bash -c  "echo 123 > /var/lib/mysql/test.txt"
```

次に、`test.txt`ファイルが`/var/lib/mysql`ディレクトリに作成されたことを確認しましょう：

```bash
$ kubectl exec catalog-mysql-0 -n catalog -- ls -larth /var/lib/mysql/ | grep -i test
-rw-r--r-- 1 root  root     4 Oct 18 13:38 test.txt
```

ここで、現在の`catalog-mysql` Podを削除します。これによってStatefulSetコントローラーが自動的に新しいcatalog-mysql Podを再作成します：

```bash
$ kubectl delete pods -n catalog -l app.kubernetes.io/component=mysql
pod "catalog-mysql-0" deleted
```

数秒待ってから、以下のコマンドを実行して`catalog-mysql` Podが再作成されたことを確認しましょう：

```bash
$ kubectl wait --for=condition=Ready pod -n catalog \
  -l app.kubernetes.io/component=mysql --timeout=30s
pod/catalog-mysql-0 condition met
$ kubectl get pods -n catalog -l app.kubernetes.io/component=mysql
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          29s
```

最後に、MySQLコンテナのシェルに戻り、`/var/lib/mysql`パスで`ls`コマンドを実行して、以前作成した`test.txt`ファイルを探しましょう：

```bash expectError=true
$ kubectl exec catalog-mysql-0 -n catalog -- cat /var/lib/mysql/test.txt
cat: /var/lib/mysql/test.txt: No such file or directory
command terminated with exit code 1
```

ご覧のとおり、`emptyDir`ボリュームは一時的なものであるため、`test.txt`ファイルはもう存在しません。今後のセクションでは、同じ実験を行い、永続ボリューム（PV）が`test.txt`ファイルを保持し、Podの再起動や障害を乗り越えて存続することを実証します。

次のページでは、KubernetesのストレージとAWSクラウドエコシステムとの統合に関する主要な概念について理解を深めます。

