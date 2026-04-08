---
title: "Podの検査"
sidebar_position: 50
tmdTranslationSourceHash: 30800eaa2f30899dfc6709dc0747f890
---

catalogポッドが実行され、Amazon RDSデータベースを正常に使用している今、そのポッドをより詳しく調べて、セキュリティグループforポッドに関連する信号を確認してみましょう。

最初に確認できるのは、ポッドのアノテーションです：

```bash
$ kubectl get pod -n catalog -l app.kubernetes.io/component=service -o yaml \
  | yq '.items[0].metadata.annotations'
kubernetes.io/psp: eks.privileged
prometheus.io/path: /metrics
prometheus.io/port: "8080"
prometheus.io/scrape: "true"
vpc.amazonaws.com/pod-eni: '[{"eniId":"eni-0eb4769ea066fa90c","ifAddress":"02:23:a2:af:a2:1f","privateIp":"10.42.10.154","vlanId":2,"subnetCidr":"10.42.10.0/24"}]'
```

`vpc.amazonaws.com/pod-eni`アノテーションは、このポッドに使用されているブランチENIに関するメタデータを示しており、そのID、MACアドレス、プライベートIPアドレス、サブネットCIDRが含まれています。

Kubernetesイベントには、追加した設定に対応してVPCリソースコントローラーがアクションを実行していることも表示されます：

```bash
$ kubectl get events -n catalog | grep SecurityGroupRequested
5m         Normal    SecurityGroupRequested   pod/catalog-6ccc6b5575-w2fvm    Pod will get the following Security Groups [sg-037ec36e968f1f5e7]
```

:::info
VPCリソースコントローラーは、ブランチネットワークインターフェースのライフサイクルの管理、それらをポッドに接続すること、およびセキュリティグループとの関連付けを担当しています。
:::

AWSコンソールでVPCリソースコントローラーによって管理されるENIを確認することもできます：

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#NIC:v=3;tag:eks:eni:owner=eks-vpc-resource-controller;tag:vpcresources.k8s.aws/trunk-eni-id=:eni" service="ec2" label="EC2コンソールを開く"/>

これにより、割り当てられたセキュリティグループなど、ブランチENIに関する情報を確認できます。これらのブランチENIはトランクインターフェースに関連付けられ、特定のポッドに専用であり、ポッドレベルでの細かいネットワークセキュリティ制御を可能にします。
