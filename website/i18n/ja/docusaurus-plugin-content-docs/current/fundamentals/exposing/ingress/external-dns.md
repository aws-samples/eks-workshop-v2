---
title: "External DNS"
sidebar_position: 30
kiteTranslationSourceHash: b7f399a9ad32bbe99ece1082753fcd42
---

[ExternalDNS](https://github.com/kubernetes-sigs/external-dns)はKubernetesコントローラーで、クラスターのサービスとイングレス用のDNSレコードを自動的に管理します。KubernetesリソースとAWS Route 53などのDNSプロバイダーとの間の橋渡しとして機能し、DNSレコードがクラスターの状態と同期されるようにします。ロードバランサーにDNSエントリを使用することで、自動生成されたホスト名の代わりに人間が読みやすく、覚えやすいアドレスを提供し、組織のブランディングに合わせたドメイン名でサービスを簡単にアクセスおよび認識できるようにします。

このラボでは、ExternalDNSとAWS Route 53を使用して、KubernetesのイングレスリソースのDNS管理を自動化します。

まず、環境変数として提供されているIAMロールARNとHelmチャートバージョンを使用して、HelmでExternalDNSをインストールしましょう：

```bash
$ helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
$ helm upgrade --install external-dns external-dns/external-dns --version "${DNS_CHART_VERSION}" \
    --namespace external-dns \
    --create-namespace \
    --set provider.name=aws \
    --set serviceAccount.create=true \
    --set serviceAccount.name=external-dns-sa \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$DNS_ROLE_ARN" \
    --set txtOwnerId=eks-workshop \
    --set extraArgs[0]=--aws-zone-type=private \
    --set extraArgs[1]=--domain-filter=retailstore.com \
    --wait
```

ExternalDNSポッドが実行されていることを確認しましょう：

```bash
$ kubectl -n external-dns get pods
NAME                                READY   STATUS    RESTARTS   AGE
external-dns-5bdb4478b-fl48s        1/1     Running   0          2m
```

次に、DNS設定を追加して以前のイングレスリソースを更新しましょう：

::yaml{file="manifests/modules/exposing/ingress/external-dns/ingress.yaml" paths="metadata.annotations,spec.rules.0.host"}

1. `external-dns.alpha.kubernetes.io/hostname`アノテーションは、ExternalDNSにイングレス用に作成および管理するDNS名を指定し、アプリのホスト名とロードバランサーのマッピングを自動化します。
2. `spec.rules.host`は、イングレスが待ち受けるドメイン名を定義し、ExternalDNSはこれを使って関連するロードバランサーの一致するDNSレコードを作成します。

この設定を適用しましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/external-dns
```

ホスト名を使用して作成されたイングレスオブジェクトを確認しましょう：

```bash wait=120
$ kubectl get ingress ui   -n ui
NAME     CLASS   HOSTS                    ADDRESS                                            PORTS   AGE
ui       alb     ui.retailstore.com       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      4m15s
```

DNSレコードの作成を確認します。ExternalDNSは`retailstore.com`のRoute 53プライベートホストゾーンにDNSレコードを自動的に作成します。

:::note

DNSエントリが調整されるまで数分かかる場合があります。

:::

ExternalDNSのログを確認してDNSレコードの作成を確認します：

```bash hook=dns-logs
$ kubectl -n external-dns logs deployment/external-dns
Desired change: CREATE ui.retailstore.com A
5 record(s) were successfully updated
```

リンクをクリックして`retailstore.com`プライベートホストゾーンに移動することで、AWS Route 53コンソールで新しいDNSレコードを確認することもできます：

<ConsoleButton url="https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones" service="route53" label="Route53コンソールを開く"/>

Route 53のプライベートホストゾーンは、関連付けられたVPC（この場合はEKSクラスターVPC）からのみアクセス可能です。DNSエントリをテストするために、ポッド内から`curl`を使用します：

```bash hook=dns-curl
$ kubectl -n ui exec -it \
  deployment/ui -- bash -c "curl -i http://ui.retailstore.com/actuator/health/liveness; echo"

HTTP/1.1 200 OK
Date: Thu, 24 Apr 2025 07:45:12 GMT
Content-Type: application/vnd.spring-boot.actuator.v3+json
Content-Length: 15
Connection: keep-alive
Set-Cookie: SESSIONID=c3f13e02-4ff3-40ba-866e-c777f7450997

{"status":"UP"}
```
