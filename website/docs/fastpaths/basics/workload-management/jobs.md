---
title: Jobs & CronJobs
sidebar_position: 34
---

# Jobs & CronJobs

**Jobs** and **CronJobs** are controllers for running **finite or recurring tasks**. Unlike Deployments or StatefulSets that keep pods running continuously, Jobs run tasks to completion, and CronJobs run Jobs on a schedule.

Key benefits:
- **Run to completion** - Pods finish the task and stop
- **Retry failed tasks** - Automatically retry based on backoff policy
- **Parallel execution** - Multiple Pods can run simultaneously
- **Scheduled tasks** - CronJobs run tasks at specific times
- **Track history** - Monitor successful and failed completions

## When to Use Jobs & CronJobs

**Use Jobs for:**
- Database migrations and schema updates
- Data processing and ETL operations
- One-time setup tasks and initialization
- Backup operations and file processing

**Use CronJobs for:**
- Regular backups (daily, weekly)
- Cleanup tasks and log rotation
- Report generation and data synchronization
- Periodic health checks and monitoring

## Deploying a Job

Let's create a data processing job:

::yaml{file="manifests/modules/introduction/basics/jobs/data-processing-job.yaml" paths="kind,metadata.name,spec.completions,spec.backoffLimit,spec.template.spec.restartPolicy" title="data-processing-job.yaml"}

1. `kind: Job`: Creates a Job controller
2. `metadata.name`: Name of the job (data-processor)
3. `spec.completions`: Number of successful completions needed (1)
4. `spec.backoffLimit`: Maximum retry attempts (3)
5. `spec.template.spec.restartPolicy`: Pods never restart on failure; the Job controller handles retries

Deploy the job:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/data-processing-job.yaml
```

## Inspecting Job

Check job status:
```bash
$ kubectl get jobs -n catalog
NAME             COMPLETIONS   DURATION   AGE
data-processor   1/1           15s        1m
```

View the job's pod:
```bash
$ kubectl get pods -n catalog -l job-name=data-processor
NAME                   READY   STATUS      RESTARTS   AGE
data-processor-h7mg7   0/1     Completed   0          25s
```

Wait for the job to complete:
```bash
$ kubectl wait --for=condition=complete --timeout=60s job/data-processor -n catalog
```

Check job logs to see the processing output:
```bash
$ kubectl logs -n catalog job/data-processor
Starting data processing job...
Processing catalog data files...
Processing file 1/5...
File 1 processed successfully
...
Data processing job completed successfully!
```

Get detailed job information:
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

## Deploying a CronJob

Let's create a cleanup CronJob that runs every 1 minutes:

::yaml{file="manifests/modules/introduction/basics/jobs/catalog-cleanup.yaml" paths="kind,metadata.name,spec.schedule,spec.jobTemplate" title="catalog-cleanup.yaml"}

1. `kind: CronJob`: Creates a CronJob controller
2. `metadata.name`: Name of the CronJob (`catalog-cleanup`)
3. `spec.schedule`: Cron schedule (`*/1 * * * *` = every 1 minutes)
4. `spec.jobTemplate`: Template for jobs that will be created

Deploy the CronJob:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/catalog-cleanup.yaml
```

## Managing CronJobs

View CronJobs:
```bash
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   False     0        <none>          30s
```

Initially, `LAST SCHEDULE` shows `<none>` because the CronJob hasn't run yet. Since our CronJob runs every minute, let's manually trigger it to see it in action immediately:

```bash
# Manually trigger a CronJob to see it work immediately
$ kubectl create job --from=cronjob/catalog-cleanup manual-cleanup -n catalog
```

Now view jobs created by the CronJob:
```bash
$ kubectl get jobs -n catalog
NAME                       STATUS     COMPLETIONS   DURATION   AGE
data-processor             Complete   1/1           13s        17m
manual-cleanup             Running    0/1           5s         5s
```

Wait for the job pod to be running before checking logs:
```bash
$ kubectl wait --for=jsonpath='{.status.phase}'=Running pod -l job-name=manual-cleanup -n catalog --timeout=60s
```

Check the logs of the job execution:
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

Wait for the CronJob to run automatically (or check back in 1 minute):
```bash
# Check if the CronJob has run automatically
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   False     0        30s             2m
```

View all jobs in the namespace (including those created by CronJobs):
```bash
$ kubectl get jobs -n catalog
NAME                       STATUS     COMPLETIONS   DURATION   AGE
catalog-cleanup-29328191   Complete   1/1           9s         114s
catalog-cleanup-29328192   Complete   1/1           9s         54s
data-processor             Complete   1/1           13s        21m
manual-cleanup             Complete   1/1           10s        56s
```

To see which jobs were created by a specific CronJob, look for jobs with names starting with the CronJob name:
```bash hook=cronjob-first-run
$ kubectl get jobs -n catalog | grep catalog-cleanup
catalog-cleanup-29328192   Complete   1/1           9s         74s
catalog-cleanup-29328193   Complete   1/1           8s         14s
```

You can also check the job's owner reference to see which CronJob created it:
```bash
$ kubectl get job manual-cleanup -n catalog -o yaml | grep -A 5 ownerReferences | yq
  ownerReferences:
  - apiVersion: batch/v1
    controller: true
    kind: CronJob
    name: catalog-cleanup
    uid: 7f2deb86-a5c7-4703-ac5e-c5dd4893ff23
```

Clean up the manual job:
```bash
$ kubectl delete job manual-cleanup -n catalog
```

### Monitoring CronJob Execution

Check CronJob status and history:
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

This shows:
- **Schedule**: When the job runs
- **Last Schedule Time**: When it last executed
- **Active**: Currently running jobs
- **Events**: Recent CronJob activity

View recent events for troubleshooting:
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

### Suspending and Resuming CronJobs

Temporarily stop a CronJob:
```bash
$ kubectl patch cronjob catalog-cleanup -n catalog -p '{"spec":{"suspend":true}}'
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   UTC        True      0        42s             24m
```

Resume a suspended CronJob:
```bash
$ kubectl patch cronjob catalog-cleanup -n catalog -p '{"spec":{"suspend":false}}'
$ kubectl get cronjobs -n catalog
NAME              SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-cleanup   */1 * * * *   UTC        False     1        16s             24m
```

## Common Cron Schedules

| Schedule | Description |
|----------|-------------|
| `0 2 * * *` | Daily at 2 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * 0` | Every Sunday at midnight |
| `*/15 * * * *` | Every 15 minutes |
| `0 9 * * 1-5` | Weekdays at 9 AM |

## Parallel Jobs

For processing multiple items simultaneously:

```yaml
spec:
  completions: 10      # Process 10 items total
  parallelism: 3       # Run 3 pods at once
```
- `completions` = total number of successful Pods
- `parallelism` = how many Pods run concurrently

This creates 10 successful completions using 3 parallel pods.

## Jobs vs Other Controllers
| Controller | Purpose | Pods run continuously? | Use Case |
|------------|---------|---------------|----------------|
| Job  | One-off task | No | Batch processing, migrations |
| CronJob  | Scheduled jobs | No | Backups, periodic reports |
| Deployment | Long-running stateless app | Yes | Web apps, APIs |
| StatefulSet | Stateful services | Yes | Databases, queues |

## Key Points to Remember

* Jobs run pods until tasks complete successfully
* CronJobs create Jobs automatically on schedules
* Use `restartPolicy: Never` for Jobs and `OnFailure` for CronJobs
* Set backoff limits to control retry attempts
* Jobs can run multiple pods in parallel for faster processing
* Clean up completed Jobs to avoid resource accumulation
* Jobs and CronJobs are ideal for finite or recurring batch tasks, not long-running services
