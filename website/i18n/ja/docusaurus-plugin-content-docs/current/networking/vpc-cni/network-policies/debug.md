---
title: "デバッグ"
sidebar_position: 90
tmdTranslationSourceHash: b00096fd2aa50adedce64127337b1173
---

これまでは、ネットワークポリシーを問題やエラーなしに適用することができました。しかし、エラーや問題が発生した場合はどうなるでしょうか？これらの問題をどのようにデバッグするのでしょうか？

Amazon VPC CNIは、ネットワークポリシーを実装する際の問題をデバッグするために使用できるログを提供します。さらに、Amazon CloudWatchなどのサービスを通じてこれらのログをモニタリングでき、CloudWatch Container Insightsを活用してNetworkPolicyの使用に関する洞察を提供することができます。

では、「ui」コンポーネントからのみ「orders」サービスコンポーネントへのアクセスを制限する入力ネットワークポリシーを実装してみましょう。これは以前に「catalog」サービスコンポーネントで行ったことと同様です。

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector`は、ラベル`app.kubernetes.io/name: orders`と`app.kubernetes.io/component: service`を持つポッドをターゲットにします
2. `ingress.from`は、ラベル`app.kubernetes.io/name: ui`を持つポッドからの着信接続のみを許可します

このポリシーを適用してみましょう：

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-fail-debug.yaml
```

そして、検証してみましょう：

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to orders.orders port 80 after 5000 ms: Timeout was reached
...
```

出力から分かるように、何かがおかしいです。「ui」コンポーネントからの呼び出しは成功するはずでしたが、代わりに失敗しました。これをデバッグするために、ネットワークポリシーエージェントのログを活用して問題がどこにあるかを確認できます。

ネットワークポリシーエージェントのログは、各ワーカーノードの`/var/log/aws-routed-eni/network-policy-agent.log`ファイルで確認できます。このファイルに記録されている`DENY`ステートメントがあるかどうか見てみましょう：

```bash test=false
$ POD_HOSTIP_1=$(kubectl get po --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].spec.nodeName')
$ kubectl debug node/$POD_HOSTIP_1 -it --image=ubuntu
# Run these commands inside the pod
$ grep DENY /host/var/log/aws-routed-eni/network-policy-agent.log | tail -5
{"level":"info","timestamp":"2023-11-03T23:02:17.916Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
{"level":"info","timestamp":"2023-11-03T23:02:18.920Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
{"level":"info","timestamp":"2023-11-03T23:02:20.936Z","logger":"ebpf-client","msg":"Flow Info:  ","Src IP":"10.42.190.65","Src Port":55986,"Dest IP":"10.42.117.209","Dest Port":8080,"Proto":"TCP","Verdict":"DENY"}
$ exit
```

出力から分かるように、「ui」コンポーネントからの呼び出しが拒否されています。さらに分析すると、ネットワークポリシーの入力セクションには、podSelectorのみがあり、namespaceSelectorがないことが分かります。namespaceSelectorが空の場合、デフォルトでネットワークポリシーの名前空間（この場合は「orders」）になります。したがって、ポリシーは「orders」名前空間からラベル「app.kubernetes.io/name: ui」に一致するポッドのみを許可するものとして解釈され、「ui」コンポーネントからのトラフィックが拒否される結果となります。

ネットワークポリシーを修正して再試行しましょう。

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-order-ingress-success-debug.yaml
```

「ui」が接続できるか確認しましょう：

```bash
$ kubectl exec deployment/ui -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* Connected to orders.orders (172.20.248.36) port 80 (#0)
> GET /orders HTTP/1.1
> Host: orders.orders
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200
...
```

出力から分かるように、「ui」コンポーネントは「orders」サービスコンポーネントを呼び出すことができるようになり、問題は解決しました。
