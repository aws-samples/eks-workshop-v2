---
title: "暗号通貨ランタイム"
sidebar_position: 531
tmdTranslationSourceHash: 5a2c9673ac514386bbd593190b43b96d
---

この検出結果は、コンテナがPod内で暗号マイニングを試みたことを示しています。

検出結果をシミュレートするために、`default`名前空間で`ubuntu`イメージのPodを実行し、そこから暗号マイニングプロセスのダウンロードをシミュレートするためのコマンドをいくつか実行します。

以下のコマンドを実行してPodを起動します：

```bash
$ kubectl run crypto -n other --image ubuntu --restart=Never --command -- sleep infinity
$ kubectl wait --for=condition=ready pod crypto -n other
```

次に`kubectl exec`を使用してPod内で一連のコマンドを実行します。まずは`curl`ユーティリティをインストールしましょう：

```bash
$ kubectl exec crypto -n other -- bash -c 'apt update && apt install -y curl'
```

次に暗号マイニングプロセスをダウンロードしますが、出力は`/dev/null`に捨てます：

```bash test=false
$ kubectl exec crypto -n other -- bash -c 'curl -s -o /dev/null http://us-east.equihash-hub.miningpoolhub.com:12026 || true && echo "Done!"'
```

これらのコマンドは[GuardDuty検出結果コンソール](https://console.aws.amazon.com/guardduty/home#/findings)で3つの異なる検出結果をトリガーします。

1つ目は`Execution:Runtime/NewBinaryExecuted`で、APTツールを介してインストールされた`curl`パッケージに関連しています。

![バイナリ実行の検出結果](/docs/security/guardduty/runtime-monitoring/binary-execution.webp)

この検出結果の詳細をよく見ると、GuardDutyランタイムモニタリングに関連しているため、ランタイム、コンテキスト、およびプロセスに関する特定の情報が表示されています。

2つ目と3つ目は`CryptoCurrency:Runtime/BitcoinTool.B!DNS`検出結果に関連しています。検出結果の詳細には異なる情報が含まれていることに注意してください。今回は`DNS_REQUEST`アクションと**脅威インテリジェンスの証拠**が表示されています。

![暗号ランタイムの検出結果](/docs/security/guardduty/runtime-monitoring/crypto-runtime.webp)
