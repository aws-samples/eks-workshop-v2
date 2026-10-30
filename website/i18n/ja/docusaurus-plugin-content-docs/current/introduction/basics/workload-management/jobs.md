---
title: Jobs & CronJobs
sidebar_position: 34
tmdTranslationSourceHash: d6e15ee9dd1af39ed725bcf68f498595
---

# Jobs & CronJobs

**Jobs**と**CronJobs**は、**有限または定期的なタスク**を実行するためのコントローラーです。Podを継続的に実行し続けるDeploymentやStatefulSetとは異なり、Jobsはタスクを完了まで実行し、CronJobsはスケジュールに従ってJobsを実行します。

主な利点:
- **完了まで実行** - Podはタスクを完了して停止します
- **失敗したタスクの再試行** - バックオフポリシーに基づいて自動的に再試行します
- **並列実行** - 複数のPodを同時に実行できます
- **スケジュールされたタスク** - CronJobsは特定の時刻にタスクを実行します
- **履歴の追跡** - 成功および失敗した完了を監視します

## JobsとCronJobsを使用する場合

**Jobsを使用する場合:**
- データベースのマイグレーションとスキーマの更新
- データ処理とETL操作
- 1回限りのセットアップタスクと初期化
- バックアップ操作とファイル処理

**CronJobsを使用する場合:**
- 定期的なバックアップ（毎日、毎週）
- クリーンアップタスクとログのローテーション
- レポート生成とデータの同期
- 定期的なヘルスチェックと監視

## Jobのデプロイ

データ処理Jobを作成しましょう:

::yaml{file="manifests/modules/introduction/basics/jobs/data-processing-job.yaml" paths="kind,metadata.name,spec.completions,spec.backoffLimit,spec.template.spec.restartPolicy" title="data-processing-job.yaml"}

1. `kind: Job`: Jobコントローラーを作成します
2. `metadata.name`: Jobの名前（data-processor）
3. `spec.completions`: 必要な成功完了数（1）
4. `spec.backoffLimit`: 最大再試行回数（3）
5. `spec.template.spec.restartPolicy`: Podは失敗時に再起動しません。Jobコントローラーが再試行を処理します

Jobをデプロイします:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/data-processing-job.yaml
```

## Jobの検査

Jobのステータスを確認します:
```bash
$ kubectl get jobs -n catalog
NAME             COMPLETIONS   DURATION   AGE
data-processor   1/1           15s        1m
```

JobのPodを表示します:
```bash
$ kubectl get pods -n catalog -l job-name=data-processor
NAME                   READY   STATUS      RESTARTS   AGE
data-processor-h7mg7   0/1     Completed   0          25s
```

Jobが完了するのを待ちます:
```bash
$ kubectl wait --for=condition=complete --timeout=60s job/data-processor -n catalog
```

Jobのログを確認して処理出力を確認します:
```bash
$ kubectl logs -n catalog job/data-processor
Starting data processing job...
Processing catalog data files...
Processing file 1/5...
File 1 processed successfully
...
Data processing job completed successfully!
```

Jobの詳細情報を取得します:
```bash
$ kubectl describe job -n catalog data-processor
Name:             data-processor
Namespace:        catalog
Selector:         batch.kubernetes.io/controller-uid=639c46e3-ee04-4914-8c97-516a14087c1d
Labels:           app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/name=data-processor
Annotations:      <none>
Parallelism:      1
Completions:      1
Completion Mode:  NonIndexed
Suspend:          false
Backoff Limit:    3
Start Time:       Sun, 05 Oct 2025 18:51:01 +0000
Completed At:     Sun, 05 Oct 2025 18:51:14 +0000
Duration:         13s
Pods Statuses:    0 Active (0 Ready) / 1 Succeeded / 0 Failed
Pod Template:
  Labels:  app=data-processor
           batch.kubernetes.io/controller-uid=639c46e3-ee04-4914-8c97-516a14087c1d
           batch.kubernetes.io/job-name=data-processor
           controller-uid=639c46e3-ee04-4914-8c97-516a14087c1d
           job-name=data-processor
  Containers:
   processor:
    Image:      busybox:1.36
    Port:       <none>
    Host Port:  <none>
    Command:
      /bin/sh
      -c
      echo "Starting data processing job..."
      echo "Processing catalog data files..."
      
      # Simulate processing multiple files
      for i in $(seq 1 5); do
        echo "Processing file $i/5..."
        sleep 2
        echo "File $i processed successfully"
      done
      
      echo "Generating summary report..."
      cat > /tmp/processing-report.txt << EOF
      Data Processing Report
      =====================
      Job: data-processor
      Date: $(date)
      Files processed: 5
      Status: Completed successfully
      EOF
      
      echo "Report generated:"
      cat /tmp/processing-report.txt
      echo "Data processing job completed successfully!"
      
    Limits:
      cpu:     200m
      memory:  256Mi
    Requests:
      cpu:         100m
      memory:      128Mi
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Events:
  Type    Reason            Age   From            Message
  ----    ------            ----  ----            -------
  Normal  SuccessfulCreate  60s   job-controller  Created pod: data-processor-h7mg7
  Normal  Completed         47s   job-controller  Job completed
```

## CronJobのデプロイ

1分ごとに実行されるクリーンアップCronJobを作成しましょう:

::yaml{file="manifests/modules/introduction/basics/jobs/catalog-cleanup.yaml" paths="kind,metadata.name,spec.schedule,spec.jobTemplate" title="catalog-cleanup.yaml"}

1. `kind: CronJob`: CronJobコントローラーを作成します
2. `metadata.name`: CronJobの名前（`catalog-cleanup`）
3. `spec.schedule`: cronスケジュール（`*/1 * * * *` = 1分ごと）
4. `spec.jobTemplate`: 作成されるJobsのテンプレート

CronJobをデプロイします:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/catalog-cleanup.yaml
```

## CronJobsの管理

CronJobsを表示します:
```bash
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   False     0        <none>          30s
```

最初は、CronJobがまだ実行されていないため、`LAST SCHEDULE`には`<none>`と表示されます。CronJobは1分ごとに実行されますが、すぐに動作を確認するために手動でトリガーしましょう:

```bash
# CronJobを手動でトリガーしてすぐに動作を確認します
$ kubectl create job --from=cronjob/catalog-cleanup manual-cleanup -n catalog
```

次に、CronJobによって作成されたJobsを表示します:
```bash
$ kubectl get jobs -n catalog
NAME                       STATUS     COMPLETIONS   DURATION   AGE
data-processor             Complete   1/1           13s        17m
manual-cleanup             Running    0/1           5s         5s
```

ログを確認する前に、JobのPodが実行中になるのを待ちます:
```bash
$ kubectl wait --for=jsonpath='{.status.phase}'=Running pod -l job-name=manual-cleanup -n catalog --timeout=60s
```

Job実行のログを確認します:
```bash
$ kubectl logs job/manual-cleanup -n catalog
Starting cleanup job at Mon Oct  5 17:30:00 UTC 2025
Checking for temporary files...
Found 3 temporary files to clean up:
  - /tmp/cache_file_1.tmp
  - /tmp/cache_file_2.tmp
  - /tmp/old_log.log
Cleaning up temporary files...
Temporary files removed successfully
Cleanup completed at Mon Oct  5 17:30:05 UTC 2025
Next cleanup scheduled in 1 minute
```

CronJobが自動的に実行されるのを待ちます（または1分後に確認します）:
```bash
# CronJobが自動的に実行されたかどうかを確認します
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   False     0        30s             2m
```

名前空間内のすべてのJobsを表示します（CronJobsによって作成されたものを含む）:
```bash
$ kubectl get jobs -n catalog
NAME                       STATUS     COMPLETIONS   DURATION   AGE
catalog-cleanup-29328191   Complete   1/1           9s         114s
catalog-cleanup-29328192   Complete   1/1           9s         54s
data-processor             Complete   1/1           13s        21m
manual-cleanup             Complete   1/1           10s        56s
```

特定のCronJobによって作成されたJobsを確認するには、CronJob名で始まるJobsを探します:
```bash hook=cronjob-first-run
$ kubectl get jobs -n catalog | grep catalog-cleanup
catalog-cleanup-29328192   Complete   1/1           9s         74s
catalog-cleanup-29328193   Complete   1/1           8s         14s
```

Jobの所有者参照を確認して、どのCronJobがそれを作成したかを確認することもできます:
```bash
$ kubectl get job manual-cleanup -n catalog -o yaml | grep -A 5 ownerReferences
  ownerReferences:
  - apiVersion: batch/v1
    controller: true
    kind: CronJob
    name: catalog-cleanup
    uid: 7f2deb86-a5c7-4703-ac5e-c5dd4893ff23
```

手動Jobをクリーンアップします:
```bash
$ kubectl delete job manual-cleanup -n catalog
```

### CronJob実行の監視

CronJobのステータスと履歴を確認します:
```bash
$ kubectl describe cronjob catalog-cleanup -n catalog
Name:                          catalog-cleanup
Namespace:                     catalog
Labels:                        app.kubernetes.io/created-by=eks-workshop
                               app.kubernetes.io/name=catalog-cleanup
Annotations:                   <none>
Schedule:                      */1 * * * *
Concurrency Policy:            Allow
Suspend:                       False
Successful Job History Limit:  3
Failed Job History Limit:      1
Starting Deadline Seconds:     <unset>
Selector:                      <unset>
Parallelism:                   <unset>
Completions:                   <unset>
Pod Template:
  Labels:  app=catalog-cleanup
  Containers:
   cleanup:
    Image:      busybox:1.36
    Port:       <none>
    Host Port:  <none>
    Command:
      /bin/sh
      -c
      echo "Starting cleanup job at $(date)"
      echo "Checking for temporary files..."
      
      # Simulate finding and cleaning up files
      echo "Found 3 temporary files to clean up:"
      echo "  - /tmp/cache_file_1.tmp"
      echo "  - /tmp/cache_file_2.tmp" 
      echo "  - /tmp/old_log.log"
      
      # Simulate cleanup process
      sleep 3
      echo "Cleaning up temporary files..."
      sleep 2
      echo "Temporary files removed successfully"
      
      echo "Cleanup completed at $(date)"
      echo "Next cleanup scheduled in 1 minute"
      
    Limits:
      cpu:     100m
      memory:  128Mi
    Requests:
      cpu:           50m
      memory:        64Mi
    Environment:     <none>
    Mounts:          <none>
  Volumes:           <none>
  Node-Selectors:    <none>
  Tolerations:       <none>
Last Schedule Time:  Sun, 05 Oct 2025 19:14:00 +0000
Active Jobs:         catalog-cleanup-29328194
Events:
  Type     Reason            Age                    From                Message
  ----     ------            ----                   ----                -------
  Normal   SuccessfulCreate  19m                    cronjob-controller  Created job catalog-cleanup-29328175
  Normal   SawCompletedJob   18m                    cronjob-controller  Saw completed job: catalog-cleanup-29328175, condition: Complete
  ...
```

これは以下を示しています:
- **Schedule**: Jobが実行される時刻
- **Last Schedule Time**: 最後に実行された時刻
- **Active**: 現在実行中のJobs
- **Events**: 最近のCronJobアクティビティ

トラブルシューティングのために最近のイベントを表示します:
```bash
$ kubectl get events -n catalog --field-selector involvedObject.name=catalog-cleanup
LAST SEEN   TYPE      REASON             OBJECT                    MESSAGE
20m         Normal    SuccessfulCreate   cronjob/catalog-cleanup   Created job catalog-cleanup-29328175
20m         Normal    SawCompletedJob    cronjob/catalog-cleanup   Saw completed job: catalog-cleanup-29328175, condition: Complete
3m28s       Warning   UnexpectedJob      cronjob/catalog-cleanup   Saw a job that the controller did not create or forgot: manual-cleanup
18m         Normal    SuccessfulCreate   cronjob/catalog-cleanup   Created job catalog-cleanup-29328176
18m         Normal    SuccessfulCreate   cronjob/catalog-cleanup   Created job catalog-cleanup-29328177
18m         Normal    SawCompletedJob    cronjob/catalog-cleanup   Saw completed job: catalog-cleanup-29328176, condition: Complete
18m         Normal    SuccessfulDelete   cronjob/catalog-cleanup   Deleted job catalog-cleanup-29328175
18m         Normal    SawCompletedJob    cronjob/catalog-cleanup   Saw completed job: catalog-cleanup-29328177, condition: Complete
17m         Normal    SuccessfulCreate   cronjob/catalog-cleanup   Created job catalog-cleanup-29328178
17m         Normal    SuccessfulDelete   cronjob/catalog-cleanup   Deleted job catalog-cleanup-29328176
17m         Normal    SawCompletedJob    cronjob/catalog-cleanup   Saw completed job: catalog-cleanup-29328178, condition: Complete
```

### CronJobsの一時停止と再開

CronJobを一時的に停止します:
```bash
$ kubectl patch cronjob catalog-cleanup -n catalog -p '{"spec":{"suspend":true}}'
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   UTC        True      0        42s             24m
```

一時停止されたCronJobを再開します:
```bash
$ kubectl patch cronjob catalog-cleanup -n catalog -p '{"spec":{"suspend":false}}'
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   UTC        False     1        16s             24m
```

## 一般的なcronスケジュール

| スケジュール | 説明 |
|----------|-------------|
| `0 2 * * *` | 毎日午前2時 |
| `0 */6 * * *` | 6時間ごと |
| `0 0 * * 0` | 毎週日曜日の午前0時 |
| `*/15 * * * *` | 15分ごと |
| `0 9 * * 1-5` | 平日の午前9時 |

## 並列Jobs

複数のアイテムを同時に処理する場合:

```yaml
spec:
  completions: 10      # 合計10個のアイテムを処理
  parallelism: 3       # 一度に3つのPodを実行
```
- `completions` = 成功したPodの合計数
- `parallelism` = 同時に実行されるPodの数

これにより、3つの並列Podを使用して10個の成功した完了が作成されます。

## Jobsと他のコントローラーの比較
| コントローラー | 目的 | Podは継続的に実行されますか？ | 使用例 |
|------------|---------|---------------|----------------|
| Job  | 1回限りのタスク | いいえ | バッチ処理、マイグレーション |
| CronJob  | スケジュールされたJobs | いいえ | バックアップ、定期レポート |
| Deployment | 長時間実行されるステートレスアプリ | はい | Webアプリ、API |
| StatefulSet | ステートフルサービス | はい | データベース、キュー |

## 覚えておくべき重要なポイント

* Jobsはタスクが正常に完了するまでPodを実行します
* CronJobsはスケジュールに従って自動的にJobsを作成します
* Jobsには`restartPolicy: Never`を、CronJobsには`OnFailure`を使用します
* バックオフ制限を設定して再試行回数を制御します
* Jobsは複数のPodを並列で実行して処理を高速化できます
* 完了したJobsをクリーンアップしてリソースの蓄積を避けます
* JobsとCronJobsは、有限または定期的なバッチタスクに最適で、長時間実行されるサービスには適していません

